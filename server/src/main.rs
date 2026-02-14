mod next;
mod prev;
mod random;
mod shift;
mod status;
mod types;

use std::{fs::{self}, sync::Arc};

use chrono::Local;
use ntex::{web::{self, middleware}};
use ntex_files as nfs;
use tokio::sync::RwLock;
use zasa::{parser::Parser, value::normalize, Normalize};

use crate::types::{WebringMember, WebsiteStatus};

const DEFAULT_NIX_WEBRING_PORT: u16 = 5932;
const DEFAULT_NIX_WEBRING_GECKODRIVER_PORT: u16 = 4444;

#[ntex::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();

    let nix_webring_dir = std::env::var("NIX_WEBRING_DIR")
        .expect("NIX_WEBRING_DIR not found");

    let nix_webring_host = std::env::var("NIX_WEBRING_HOST")
        .unwrap_or("127.0.0.1".to_string());

    let nix_webring_port = std::env::var("NIX_WEBRING_PORT")
        .map(|p|
            p.parse::<u16>()
                .expect("NIX_WEBRING_PORT has to be u16")
        )
        .unwrap_or(DEFAULT_NIX_WEBRING_PORT);

    let nix_webring_geckodriver_port = std::env::var("NIX_WEBRING_GECKODRIVER_PORT")
        .map(|p|
            p.parse::<u16>()
                .expect("NIX_WEBRING_GECKODRIVER_PORT has to be u16")
        )
        .unwrap_or(DEFAULT_NIX_WEBRING_GECKODRIVER_PORT);

    let path = format!("{nix_webring_dir}/webring.json");
    let json = fs::read_to_string(&path)
        .unwrap_or_else(|_| panic!("couldn't open {path}"));

    let members = Arc::new(RwLock::new({
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

    tokio::spawn(status::website_checker(Arc::clone(&members), nix_webring_geckodriver_port));

    web::server(async move || {
        web::App::new()
            .middleware(middleware::Logger::default())
            .state(Arc::clone(&members))
            .service(
                web::scope("/")
                    .service(next::next)
                    .service(prev::prev)
                    .service(random::random)
                    .service(status::status)
                    .service(
                        nfs::Files::new("/", nix_webring_dir.clone())
                            .index_file("index.html")
                            .redirect_to_slash_directory()
                    )
            )
    })
    .bind((nix_webring_host, nix_webring_port))?
    .run()
    .await
}
