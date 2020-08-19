defmodule Games.Chat do
  @global_chat "chat:global"

  @doc """
  Name of the global chat, for use in PubSub.
  """
  def global_chat(), do: @global_chat

  @doc """
  Broadcasts a message in the gloal channel that invites a user to a game.
  """
  def game_invite(user, invited_user) do
    Games.Chat.Message.new_game_invite(user, invited_user)
    |> Games.Chat.Message.save()
    |> broadcast_message()
  end

  @doc """
  Broadcasts a message in the gloal channel.
  """
  def global_text_message(user, text) when is_binary(text) do
    Games.Chat.Message.new_text(user, text)
    |> Games.Chat.Message.save()
    |> broadcast_message()
  end

  @doc """
  Subscribe to Games.PubSub @global_chat.
  """
  def subscribe(:global) do
    Phoenix.PubSub.subscribe(Games.PubSub, @global_chat)
  end

  ### PRIVATE ###

  defp broadcast_message(%Games.Chat.Message{} = message) do
    Phoenix.PubSub.broadcast(Games.PubSub, @global_chat, message)
  end
end
