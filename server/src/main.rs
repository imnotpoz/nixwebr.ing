use std::{fs::{self}, sync::Arc, thread, time::Duration};

use chrono::{DateTime, Local};
use ntex::{http::{header, Response}, web::{self, middleware}};
use ntex_files as nfs;
use ::rand::{rng, Rng};
use tokio::sync::Mutex;
use zasa::{parser::Parser, value::{denormalize, normalize}, Normalize};

#[derive(Clone, Debug)]
enum WebsiteStatus {
    Ok,
    BrokenLinks,
    Unreachable,
    Unknown,
}

#[derive(Clone)]
struct WebringMember {
    name: String,
    site: String,
    site_status: WebsiteStatus,
    last_checked: DateTime<Local>,
}

#[web::get("/next/{name}")]
async fn next(
    members: web::types::State<Arc<Mutex<Vec<WebringMember>>>>,
    name: web::types::Path<String>,
) -> impl web::Responder {
    let members = members.lock().await;

    if let Some((i, _)) = members.iter().enumerate().find(|(_, member)| member.name == *name) {
        let next_index = (i + 1) % members.len();
        let next_site = &members[next_index].site;

        return Response::PermanentRedirect()
            .header(header::LOCATION, next_site)
            .header(header::CACHE_CONTROL, "no-store")
            .take();
    }

    Response::TemporaryRedirect()
        .header(header::LOCATION, "https://nixwebr.ing/invalid-member.html")
        .header(header::CACHE_CONTROL, "no-store")
        .take()
}

#[web::get("/prev/{name}")]
async fn prev(
    members: web::types::State<Arc<Mutex<Vec<WebringMember>>>>,
    name: web::types::Path<String>,
) -> impl web::Responder {
    let members = members.lock().await;

    if let Some((i, _)) = members.iter().enumerate().find(|(_, member)| member.name == *name) {
        let prev_index = if i == 0 { members.len() - 1 } else { i - 1 };
        let prev_site = &members[prev_index].site;

        return Response::PermanentRedirect()
            .header(header::LOCATION, prev_site)
            .header(header::CACHE_CONTROL, "no-store")
            .take();
    }

    Response::TemporaryRedirect()
        .header(header::LOCATION, "https://nixwebr.ing/invalid-member.html")
        .header(header::CACHE_CONTROL, "no-store")
        .take()
}

#[web::get("/rand")]
async fn rand(
    members: web::types::State<Arc<Mutex<Vec<WebringMember>>>>,
) -> impl web::Responder {
    let members = members.lock().await;

    let rand_index = rng().random_range(0..members.len());
    let rand_site = &members[rand_index].site;

    Response::PermanentRedirect()
        .header(header::LOCATION, rand_site)
        .header(header::CACHE_CONTROL, "no-store")
        .take()
}

async fn website_checker(members: Arc<Mutex<Vec<WebringMember>>>) {
    let day = Duration::from_secs(24 * 60 * 60);
    loop {
        let client = reqwest::Client::new();
        let start = Local::now();

        let mut members = members.lock().await;

        for member in members.iter_mut() {
            let response = client.get(&member.site)
                .send().await;

            let site_status = match response {
                Ok(resp) => {
                    match resp.text().await {
                        Ok(text) => {
                            let links_present = text.contains(&format!("https://nixwebr.ing/prev/{}", member.name))
                                && text.contains(&format!("https://nixwebr.ing/next/{}", member.name));

                            if links_present {
                                WebsiteStatus::Ok
                            } else {
                                WebsiteStatus::BrokenLinks
                            }
                        },
                        Err(_) => WebsiteStatus::Unknown,
                    }
                },
                Err(_) => WebsiteStatus::Unreachable,
            };

            let last_checked = Local::now();

            member.site_status = site_status;
            member.last_checked = last_checked;
        }

        drop(members);

        let end = Local::now();
        let elapsed = end.naive_local() - start.naive_local();
        thread::sleep(day - elapsed.to_std().expect("this should never be negative"));
    }
}

#[web::get("/status/{name}")]
async fn status(
    members: web::types::State<Arc<Mutex<Vec<WebringMember>>>>,
    name: web::types::Path<String>,
) -> impl web::Responder {
    let members = members.lock().await;

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

#[ntex::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();

    let nix_webring_dir = std::env::var("NIX_WEBRING_DIR")
        .expect("NIX_WEBRING_DIR not found");

    let nix_webring_port = std::env::var("NIX_WEBRING_PORT")
        .expect("NIX_WEBRING_PORT not found")
        .parse::<u16>()
        .expect("NIX_WEBRING_PORT has to be u16");

    let path = format!("{nix_webring_dir}/webring.json");
    let json = fs::read_to_string(&path)
        .unwrap_or_else(|_| panic!("couldn't open {path}"));

    let members = Arc::new(Mutex::new({
        #[derive(Normalize)]
        struct Member {
            name: String,
            site: String,
        }

        let members: Vec<Member> = normalize(Parser::new(json.chars()).parse().unwrap())
            .unwrap_or_else(|_| panic!("failed deserializing webring members: {json}"));

        members.into_iter()
            .map(|Member { name, site }| WebringMember {
                name, site,
                site_status: WebsiteStatus::Unknown,
                last_checked: Local::now(),
            })
            .collect::<Vec<_>>()
    }));

    tokio::spawn(website_checker(Arc::clone(&members)));

    web::server(move || {
        web::App::new()
            .wrap(middleware::Logger::default())
            .state(Arc::clone(&members))
            .service(
                web::scope("/")
                    .service(next)
                    .service(prev)
                    .service(rand)
                    .service(
                        nfs::Files::new("/", nix_webring_dir.clone())
                            .index_file("index.html")
                            .redirect_to_slash_directory()
                    )
            )
    })
    .bind(("127.0.0.1", nix_webring_port))?
    .run()
    .await
}
