import Config

config :chatbot, :environment, config_env()

config :nostrum, gateway_intents: :all

config :openai, http_options: [recv_timeout: 30_000]
