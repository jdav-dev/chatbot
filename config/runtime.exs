import Config

if config_env() == :prod do
  config :nostrum, token: System.fetch_env!("DISCORD_TOKEN")

  config :openai,
    api_key: System.fetch_env!("OPENAI_API_KEY"),
    organization_key: System.fetch_env!("OPENAI_ORGANIZATION_KEY")
end
