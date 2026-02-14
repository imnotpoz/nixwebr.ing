use chrono::{DateTime, Local};

#[derive(Clone, Debug, Default, PartialEq)]
pub enum WebsiteStatus {
    Ok,
    BrokenLinks,
    Unreachable,
    #[default]
    Unknown,
}

#[derive(Clone, Debug)]
pub struct WebringMember {
    pub name: String,
    pub site: String,
    pub site_status: WebsiteStatus,
    pub last_checked: DateTime<Local>,
}
