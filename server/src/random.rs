use std::sync::Arc;

use ntex::{http::{Response, header}, web};
use rand::{RngExt, rng};
use tokio::sync::RwLock;

use crate::types::WebringMember;

#[web::get("/rand")]
pub async fn random(
    members: web::types::State<Arc<RwLock<Vec<WebringMember>>>>,
) -> impl web::Responder {
    let members = members.read().await;

    let rand_index = rng().random_range(0..members.len());
    let rand_site = &members[rand_index].site;

    Response::PermanentRedirect()
        .header(header::LOCATION, rand_site)
        .header(header::CACHE_CONTROL, "no-store")
        .take()
}
