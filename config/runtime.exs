import Config

config :nostrum,
  token: System.fetch_env!("DISCORD_TOKEN"),
  gateway_intents: :all

config :openai,
  api_key: System.fetch_env!("OPENAI_API_KEY"),
  organization_key: System.fetch_env!("OPENAI_ORGANIZATION_KEY"),
  http_options: [recv_timeout: 30_000]
