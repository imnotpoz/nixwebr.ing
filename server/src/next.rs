use std::sync::Arc;

use ntex::{http::{Response, header}, web};
use tokio::sync::RwLock;

use crate::{shift::shift_ring, types::WebringMember};

#[web::get("/next/{name}")]
pub async fn next(
    members: web::types::State<Arc<RwLock<Vec<WebringMember>>>>,
    name: web::types::Path<String>,
) -> impl web::Responder {
    let members = members.read().await;

    let (found, site) = shift_ring(&members, &name, true)
        .map_or(
            (false, "https://nixwebr.ing/invalid-member.html".to_string()),
            |s| (true, s)
        );

    let mut resp = if found {
        Response::PermanentRedirect()
    } else {
        Response::TemporaryRedirect()
    };

    resp
        .header(header::LOCATION, &site)
        .header(header::CACHE_CONTROL, "no-store")
        .take()
}
