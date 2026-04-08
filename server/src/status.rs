use std::{sync::Arc, time::Duration};

use chrono::Local;
use ntex::{http::Response, web};
use tokio::sync::RwLock;
use zasa::{Normalize, value::denormalize};

use crate::types::{WebringMember, WebsiteStatus};

fn links_present(member_name: &str, website_source: &str) -> bool {
    let prev_link = format!("nixwebr.ing/prev/{}", member_name);
    let next_link = format!("nixwebr.ing/next/{}", member_name);

    (website_source.contains(&prev_link)
        || website_source.contains(&html_escape::encode_safe(&prev_link).to_string()))
    && (website_source.contains(&next_link)
        || website_source.contains(&html_escape::encode_safe(&next_link).to_string()))
}

const FETCH_TRIES: u8 = 5;
const FETCH_TIMEOUT: Duration = Duration::from_secs(15);

pub async fn website_checker(
    members: Arc<RwLock<Vec<WebringMember>>>,
    geckodriver_port: u16,
) {
    let day = Duration::from_secs(24 * 60 * 60);
    loop {
        let reqwest_client = reqwest::ClientBuilder::new()
            .timeout(FETCH_TIMEOUT)
            .build()
            .expect("failed creating reqwest client");
        let start = Local::now();

        let mut members = members.write().await;

        for member in members.iter_mut() {
            let mut site_status = WebsiteStatus::Unknown;
            let mut fantoccini_client = None;

            for _ in 0..FETCH_TRIES {
                let response = reqwest_client.get(&member.site)
                    .send().await;

                match response {
                    Ok(resp) => {
                        match resp.text().await {
                            Ok(text) => {

                                if links_present(&member.name, &text) {
                                    println!("found webring links on {}'s website! (status ok)", member.name);
                                    site_status = WebsiteStatus::Ok;
                                    break;
                                } else {
                                    // only attempt this if the raw source doesn't have any links
                                    if fantoccini_client.is_none() {
                                        fantoccini_client = Some(
                                            fantoccini::ClientBuilder::rustls()
                                                .expect("failed creating fantoccini client")
                                                .connect(&format!("http://localhost:{geckodriver_port}"))
                                                .await
                                                .expect("failed connecting to geckodriver")
                                        );
                                    }

                                    let fantoccini_client = fantoccini_client.as_ref()
                                        .expect("this was literally set to Some one line above");

                                    fantoccini_client.goto(&member.site)
                                        .await
                                        .unwrap_or_else(|_| panic!("failed connecting to {}'s website with fantoccini", member.name));

                                    let site_source = fantoccini_client.source()
                                        .await
                                        .unwrap_or_else(|_| panic!("failed fetching {}'s website source", member.name));

                                    if links_present(&member.name, &site_source) {
                                        println!("found webring links on {}'s website! (status ok)", member.name);
                                        site_status = WebsiteStatus::Ok;
                                        break;
                                    } else {
                                        eprintln!("couldn't find webring links on {}'s website! (status broken links)", member.name);
                                        eprintln!("website source: {site_source}");
                                        site_status = WebsiteStatus::BrokenLinks;
                                        break;
                                    }
                                }
                            },
                            Err(e) => {
                                eprintln!("couldn't fetch {}'s website source! (status unknown)", member.name);
                                eprintln!("reason: {e}");
                                site_status = WebsiteStatus::Unknown;
                                break;
                            },
                        }
                    },
                    Err(e) => {
                        eprintln!("couldn't reach {}'s website! (status unreachable)", member.name);
                        eprintln!("reason: {e}");
                        site_status = WebsiteStatus::Unreachable;
                        continue;
                    },
                }
            }

            if let Some(client) = fantoccini_client {
                client.close()
                    .await
                    .expect("failed closing fantoccini session");
            }

            let last_checked = Local::now();

            member.site_status = site_status;
            member.last_checked = last_checked;
        }

        drop(members);

        let end = Local::now();
        let elapsed = end.naive_local() - start.naive_local();
        tokio::time::sleep(day - elapsed.to_std().expect("this should never be negative")).await;
    }
}

#[web::get("/status/{name}")]
pub async fn status(
    members: web::types::State<Arc<RwLock<Vec<WebringMember>>>>,
    name: web::types::Path<String>,
) -> impl web::Responder {
    let members = members.read().await;

    if let Some(member) = members.iter().find(|member| member.name == *name) {
        #[derive(Normalize)]
        struct Status {
            status: String,
            last_checked: String,
        }

        let status = Status {
            status: format!("{:?}", member.site_status),
            last_checked: member.last_checked.to_rfc3339(),
        };

        return Response::Ok()
            .body(denormalize(status).into_json());
    }

    Response::NotFound()
        .finish()
}
