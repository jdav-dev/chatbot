import Config

config :nostrum, token: System.get_env("DISCORD_TOKEN")

config :openai,
  api_key: System.get_env("OPENAI_API_KEY"),
  organization_key: System.get_env("OPENAI_ORGANIZATION_KEY")
