defmodule Games.Chat do
  @global_chat "chat:global"

  @doc """
  Name of the global chat, for use in PubSub.
  """
  def global_chat(), do: @global_chat

  @doc """
  Broadcast to Games.PubSub @global_chat.
  """
  # def broadcast_message(nil, _), do: nil
  def broadcast_message(%Games.Chat.Message{} = message, :global) do
    Phoenix.PubSub.broadcast(Games.PubSub, @global_chat, message)
  end

  @doc """
  Subscribe to Games.PubSub @global_chat.
  """
  def subscribe(:global) do
    Phoenix.PubSub.subscribe(Games.PubSub, @global_chat)
  end
end
