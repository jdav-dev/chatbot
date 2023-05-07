defmodule Chatbot.Consumer do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Cache.Me

  require Logger

  @channel_id 1_050_990_075_581_829_120

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  @impl Nostrum.Consumer
  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    me = Me.get()

    if message.channel_id == @channel_id and message.author.id != me.id and message.content != "" do
      handle_message(message)
    else
      :ignore
    end
  end

  def handle_event(_event) do
    :ignore
  end

  defp handle_message(message) do
    Api.start_typing(message.channel_id)

    case Chatbot.asking_for_image(message.content) do
      {:yes, image_prompt, filename} ->
        Api.start_typing(message.channel_id)
        {:ok, image} = Chatbot.generate_image(image_prompt)

        Api.start_typing(message.channel_id)
        Api.create_message(message.channel_id, file: %{name: filename, body: image})

      :no ->
        me = Me.get()

        messages =
          for previous_message <-
                Api.get_channel_messages!(message.channel_id, 99, {:before, message.id}),
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
    "#{message.author.username} said #{message.content}"
  end
end
