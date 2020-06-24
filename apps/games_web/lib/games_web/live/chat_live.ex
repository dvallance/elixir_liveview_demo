defmodule GamesWeb.ChatLive do
  use GamesWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:messages, Games.Chat.retrieve_messages())

    if connected?(socket) do
      Games.Chat.subscribe(:global)
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("post_message", %{"chat" => %{"text" => text}} = _params, socket) do
    Games.Chat.generate_message(text)
    |> Games.Chat.save_message()
    |> Games.Chat.broadcast_message(:global)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Games.Chat.Message{} = message, socket) do
    socket = update(socket, :messages, &([message | &1]))

    {:noreply, socket}
  end
end
