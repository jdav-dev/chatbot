defmodule Chatbot.Consumer do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Cache.Me
  alias Nostrum.Struct.Message
  alias Nostrum.Struct.User

  require Logger

  @channel_id 1_050_990_075_581_829_120

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  @impl Nostrum.Consumer
  def handle_event(event) do
    me = Me.get()

    case event do
      {:MESSAGE_CREATE, %Message{channel_id: @channel_id, author: %User{id: author_id}} = message,
       _ws_state}
      when author_id != me.id ->
        handle_message(message)

      event ->
        :ignore
    end
  end

  defp handle_message(message) do
    Api.start_typing(message.channel_id)

    case Chatbot.asking_for_image(message.content) do
      {:yes, image_prompt, filename} ->
        {:ok, image} = Chatbot.generate_image(image_prompt)
        Api.create_message(message.channel_id, file: %{name: filename, body: image})

      :no ->
        {:ok, response} = Chatbot.chat(message.content)
        Api.create_message(message.channel_id, response)
    end
  rescue
    error ->
      Logger.error("handle message error: #{inspect(error)}")
      Api.create_message(message.channel_id, "No.")
  end
end
