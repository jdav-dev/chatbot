defmodule Chatbot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @environment Application.compile_env!(:chatbot, :environment)

  @impl Application
  def start(_type, _args) do
    children =
      [
        Chatbot.Config
      ]
      |> nostrum_children(@environment)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chatbot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @dialyzer {:no_match, nostrum_children: 2}
  defp nostrum_children(children, :test), do: children
  defp nostrum_children(children, _env), do: children ++ [Chatbot.Consumer]
end
