defmodule Chatbot do
  @moduledoc """
  Documentation for `Chatbot`.
  """

  @openai_chat_model "gpt-3.5-turbo"

  def asking_for_image(prompt) do
    system_message = """
    You are an AI assistant that determines if users are describing an image.
    """

    user_message = """
    You will read the following message and determine if it is describing any sort of image.
    Respond with valid JSON containing an "asking_for_image" boolean, a "prompt" field with an
    image generation prompt of the described image in as few words as possible, and a "filename"
    field with a PNG filename for the image.
    ---
    MESSAGE
    #{prompt}
    ---
    JSON FORMAT
    {
      "asking_for_image": true,
      "prompt": "",
      "filename": ""
    }
    """

    with {:ok, %{choices: [choice]}} <-
           OpenAI.chat_completion(
             model: @openai_chat_model,
             messages: [
               %{role: "system", content: system_message},
               %{role: "user", content: user_message}
             ]
           ) do
      case Jason.decode(choice["message"]["content"]) do
        {:ok, %{"asking_for_image" => true, "prompt" => image_prompt, "filename" => filename}} ->
          {:yes, image_prompt, filename}

        _ ->
          :no
      end
    end
  end

  def chat(prompt) do
    with {:ok, %{choices: [choice]}} <-
           OpenAI.chat_completion(
             model: @openai_chat_model,
             messages: [
               %{
                 role: "system",
                 content: "You are Elmo.  Answer as concisely as possible, as Elmo."
               },
               %{role: "user", content: prompt}
             ]
           ) do
      {:ok, choice["message"]["content"]}
    end
  end

  def generate_image(prompt) do
    with {:ok, %{data: [%{"b64_json" => b64_json}]}} <-
           OpenAI.image_generations(
             prompt: prompt,
             size: "1024x1024",
             response_format: "b64_json"
           ) do
      Base.decode64(b64_json)
    end
  end
end
