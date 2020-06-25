defmodule Games.Chat.Message do
  @moduledoc """
  A struct type of Message.

  e.g. %Message{type: :text, text: text}
  """
  defstruct [:type, :user, :text]

  @doc """
  Safe way to create a %Message{}
  """
  def new(%Games.User{} = user, text) do
    %Games.Chat.Message{type: :text, user: user, text: text}
  end

  defdelegate save(message), to: Games.ChatAgent, as: :save_message
  defdelegate all(), to: Games.ChatAgent, as: :retrieve_messages
end
