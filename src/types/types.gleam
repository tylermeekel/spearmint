import gleam/json

pub type Application {
  Application(id: String, name: String, owner_id: String)
}

pub fn encode_application(application: Application) -> json.Json {
  json.object([
    #("id", json.string(application.id)),
    #("name", json.string(application.name)),
    #("owner_id", json.string(application.owner_id)),
  ])
}

pub type Campaign {
  Campaign(
    id: String,
    name: String,
    description: String,
    application_id: String,
  )
}

pub type CampaignOption {
  CampaignOption(
    id: String,
    name: String,
    description: String,
    campaign_id: String,
  )
}

pub type User {
  User(id: String, public_key: String, campaign_option_id: String)
}

pub type CampaignOptionStatistic {
  CampaignOptionStatistic(
    id: String,
    name: String,
    description: String,
    campaign_option_id: String,
  )
}

pub type MeasuredDatapoint {
  MeasuredDatapoint(
    id: String,
    statistic_id: String,
    time_started: String,
    time_ended: String,
    converted: Bool,
    public_key_id: String,
  )
}
