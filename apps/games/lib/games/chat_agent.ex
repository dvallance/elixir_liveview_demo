defmodule Games.ChatAgent do
  alias Games.Chat.Message
  use Agent
  @message_limit 50

  @moduledoc """
  Simple way to store all messages. 
  """

  @doc """
  Starts our ChatAgent. 
  """
  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @doc """
  Stores only upto @message_limit messages.
  """
  def save_message(%Message{} = message) do
    Agent.update(__MODULE__, fn messages ->
      case length(messages) do
        length when length > @message_limit -> [message | remove_oldest_message(messages)]
        _length -> [message | messages]
      end
    end)

    message
  end

  @doc """
  Retrieves all messages. 
  """
  def retrieve_messages() do
    Agent.get(__MODULE__, fn messages -> messages end)
  end

  # Removes the oldest message in list.
  defp remove_oldest_message(messages) do
    # fastest method of removing tail message from list.
    messages |> Enum.reverse() |> tl() |> Enum.reverse()
  end
end
