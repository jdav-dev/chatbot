defmodule Chatbot.Consumer do
  use Nostrum.Consumer

  alias Chatbot.Config
  alias Nostrum.Api
  alias Nostrum.Cache.Me

  require Logger

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  @impl Nostrum.Consumer
  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    me = Me.get()

    with :not_my_message <- my_message(message, me),
         :has_content <- has_content(message),
         true <- mentioned?(message, me) or random_interest?() do
      handle_message(message)
    else
      reason ->
        case reason do
          false -> Logger.info("not_interested: #{message.id}")
          reason -> Logger.info("#{reason}: #{message.id}")
        end

        :ignore
    end
  end

  def handle_event(_event) do
    :ignore
  end

  defp my_message(message, me) do
    if message.author.id == me.id, do: :my_message, else: :not_my_message
  end

  defp has_content(message) do
    if message.content != "", do: :has_content, else: :no_content
  end

  defp mentioned?(message, me) do
    Enum.any?(message.mentions, &(&1.id == me.id))
  end

  defp random_interest? do
    Enum.random(1..100) > Config.get(:percent_interest, 50)
  end

  defp handle_message(message) do
    Api.start_typing(message.channel_id)

    case Chatbot.asking_for_image(message.content) do
      {:yes, image_prompt, filename} ->
        Api.start_typing(message.channel_id)
        {:ok, image} = Chatbot.generate_image(image_prompt)

        Api.start_typing(message.channel_id)

        Api.create_message(message.channel_id,
          content: image_prompt,
          file: %{name: filename, body: image}
        )

      :no ->
        me = Me.get()
        limit = :messages_limit |> Config.get(99) |> max(0)

        messages =
          for previous_message <-
                Api.get_channel_messages!(message.channel_id, limit, {:before, message.id}),
              previous_message.content != "",
              reduce: [%{role: "user", content: content(message)}] do
            acc ->
              formatted_message =
                if previous_message.author.id == me.id do
                  %{role: "assistant", content: previous_message.content}
                else
                  %{role: "user", content: content(previous_message)}
                end

              [formatted_message | acc]
          end

        Api.start_typing(message.channel_id)
        {:ok, response} = Chatbot.chat(messages)

        Api.start_typing(message.channel_id)
        Api.create_message(message.channel_id, response)
    end
  rescue
    error ->
      Logger.error("handle message error: #{inspect(error)}")
      Api.create_message(message.channel_id, "No.")
  end

  defp content(message) do
    content =
      for mention <- message.mentions, reduce: message.content do
        acc -> String.replace(acc, "<@#{mention.id}>", "@#{mention.username}")
      end

    "@#{message.author.username} said #{content}"
  end
end
