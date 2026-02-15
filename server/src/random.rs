use std::sync::Arc;

use ntex::{http::{Response, header}, web};
use rand::{RngExt, rng};
use tokio::sync::RwLock;

use crate::types::{WebringMember, WebsiteStatus};

#[web::get("/rand")]
pub async fn random(
    members: web::types::State<Arc<RwLock<Vec<WebringMember>>>>,
) -> impl web::Responder {
    let members = members.read().await;

    let working_members = members.iter()
        .filter(|WebringMember { ref site_status, .. }|
            *site_status == WebsiteStatus::Ok
            || *site_status == WebsiteStatus::BrokenLinks
        )
        .collect::<Vec<_>>();

    let rand_index = rng().random_range(0..working_members.len());
    let rand_site = &working_members[rand_index].site;

    Response::PermanentRedirect()
        .header(header::LOCATION, rand_site)
        .header(header::CACHE_CONTROL, "no-store")
        .take()
}
