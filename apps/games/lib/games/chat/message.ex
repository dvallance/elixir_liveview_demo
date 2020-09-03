defmodule Games.Chat.Message do
  @moduledoc """
  A struct type of Message.

  e.g. %Message{type: :text, user: user, meta: [text: text]}
  """
  defstruct [:type, :user, meta: []]

  @typedoc """
  Message data type. 
  """
  @type t :: %__MODULE__{
          type: atom(),
          user: Games.User.t(),
          meta: keyword()
        }

  @doc """
  Safe way to create a message `t:t/0` with a __type__ of __:text__.
  """
  @spec new_text(Games.User.t(), String.t()) :: t()
  def new_text(%Games.User{} = user, text) do
    %Games.Chat.Message{type: :text, user: user, meta: [text: text]}
  end

  @doc """
  Safe way to create a message `t:t/0` with a __type__ of __:game_invite__.
  """
  @spec new_text(Games.User.t(), Games.User.t()) :: t()
  def new_game_invite(%Games.User{} = user, invited_user) do
    %Games.Chat.Message{type: :game_invite, user: user, meta: [user: invited_user]}
  end

  defdelegate save(message), to: Games.ChatAgent, as: :save_message
  defdelegate all(), to: Games.ChatAgent, as: :retrieve_messages
end
