import gleam/json.{type Json}

type Application {
  Application(id: String, name: String, owner_id: String)
}

type Campaign {
  Campaign(
    id: String,
    name: String,
    description: String,
    application_id: String,
  )
}

type CampaignOption {
  CampaignOption(
    id: String,
    name: String,
    description: String,
    campaign_id: String,
  )
}

type User {
  User(id: String, public_key: String, campaign_option_id: String)
}

type CampaignOptionStatistic {
  CampaignOptionStatistic(
    id: String,
    name: String,
    description: String,
    campaign_option_id: String,
  )
}

type MeasuredDatapoint {
  MeasuredDatapoint(
    id: String,
    statistic_id: String,
    time_started: String,
    time_ended: String,
    converted: Bool,
    public_key_id: String,
  )
}
