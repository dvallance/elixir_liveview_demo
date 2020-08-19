defmodule Games.Chat.Message do
  @moduledoc """
  A struct type of Message.

  e.g. %Message{type: :text, user: user, meta: [text: text]}
  """
  defstruct [:type, :user, meta: []]

  @doc """
  Safe way to create a %Message{}
  """
  def new_text(%Games.User{} = user, text) do
    %Games.Chat.Message{type: :text, user: user, meta: [text: text]}
  end

  @doc """
  For use with safe sources, not user input.
  """
  def new_game_invite(%Games.User{} = user, invited_user) do
    %Games.Chat.Message{type: :game_invite, user: user, meta: [user: invited_user]}
  end

  defdelegate save(message), to: Games.ChatAgent, as: :save_message
  defdelegate all(), to: Games.ChatAgent, as: :retrieve_messages
end
