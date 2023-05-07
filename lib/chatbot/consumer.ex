defmodule Chatbot.Consumer do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Cache.Me

  require Logger

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  @impl Nostrum.Consumer
  def handle_event(
        {:MESSAGE_CREATE,
         %Nostrum.Struct.Message{
           channel_id: 1_050_990_075_581_829_120,
           content: "image me " <> prompt
         } = message, _ws_state}
      ) do
    me = Me.get()

    with false <- me.id == message.author.id,
         {:ok, %{data: [%{"b64_json" => b64_json}]}} <-
           OpenAI.image_generations(
             prompt: prompt,
             size: "1024x1024",
             response_format: "b64_json"
           ),
         {:ok, image} <- Base.decode64(b64_json) do
      Api.create_message(message.channel_id, file: %{name: "image.png", body: image})
    else
      true ->
        :ignore

      error ->
        Logger.error("handle message error: #{inspect(error)}")
        Api.create_message(message.channel_id, "No.")
    end
  end

  def handle_event(
        {:MESSAGE_CREATE,
         %Nostrum.Struct.Message{channel_id: 1_050_990_075_581_829_120} = message, _ws_state}
      ) do
    me = Me.get()

    with false <- me.id == message.author.id,
         {:ok, %{choices: [choice]} = result} <-
           OpenAI.chat_completion(
             model: "gpt-3.5-turbo",
             messages: [
               %{
                 role: "system",
                 content: "You are Elmo.  Answer as concisely as possible, as Elmo."
               },
               %{role: "user", content: message.content}
             ]
           ) do
      IO.inspect(result, label: :openai_result)

      Api.create_message(message.channel_id, choice["message"]["content"])
    else
      true ->
        :ignore

      error ->
        Logger.error("handle message error: #{inspect(error)}")
        Api.create_message(message.channel_id, "No.")
    end
  end

  def handle_event(_event) do
    :noop
  end
end
