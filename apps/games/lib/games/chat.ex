defmodule Games.Chat do
  @global_chat "chat:global"

  defmodule Message do
    @moduledoc """
    A struct type of Message.

    e.g. %Message{type: :text, text: text}
    """
    defstruct [:type, :text]
  end

  def generate_message(text) do
    %Message{type: :text, text: text}
  end

  defdelegate save_message(message), to: Games.ChatAgent
  defdelegate retrieve_messages(), to: Games.ChatAgent

  @doc """
  Broadcast to Games.PubSub @global_chat.
  """
  # def broadcast_message(nil, _), do: nil
  def broadcast_message(%Message{} = message, :global) do
    Phoenix.PubSub.broadcast(Games.PubSub, @global_chat, message)
  end

  @doc """
  Subscribe to Games.PubSub @global_chat.
  """
  def subscribe(:global) do
    Phoenix.PubSub.subscribe(Games.PubSub, @global_chat)
  end
end
