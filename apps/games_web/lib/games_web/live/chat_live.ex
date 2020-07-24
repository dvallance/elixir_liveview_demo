defmodule GamesWeb.ChatLive do
  use GamesWeb, :live_view
  alias Games.User
  import GamesWeb.LiveHelper

  @impl true
  def render(assigns) do
    Phoenix.View.render(GamesWeb.ChatView, "chat.html", assigns)
  end

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Games.Chat.subscribe(:global)
      track_user_by_presence(session)
    end

    socket =
      socket
      |> assign(:messages, Games.Chat.Message.all())
      |> assign(:users, get_users_from_presence())
      |> assign_current_user(session)

    {:ok, socket}
  end

  @impl true
  def handle_event("post_message", %{"chat" => %{"text" => text}} = _params, socket) do
    Games.Chat.Message.new(socket.assigns.current_user, text)
    |> Games.Chat.Message.save()
    |> Games.Chat.broadcast_message(:global)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Games.Chat.Message{} = message, socket) do
    socket = update(socket, :messages, &[message | &1])

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        %{
          topic: _topic,
          event: "presence_diff",
          payload: %{joins: join_data, leaves: leave_data}
        },
        socket
      ) do
    socket =
      update(socket, :users, fn users ->
        users
        |> alter_users(join_data, :join)
        |> alter_users(leave_data, :leave)
      end)

    {:noreply, socket}
  end

  defp track_user_by_presence(session) do
    GamesWeb.Presence.track(
      self(),
      Games.Chat.global_chat(),
      user_from_session(session).name,
      user_from_session(session)
    )
  end

  defp get_users_from_presence() do
    GamesWeb.Presence.list(Games.Chat.global_chat())
    |> Map.keys()
    |> Enum.map(&User.new/1)
    |> MapSet.new()
  end

  defp alter_users(users, data, join_or_leave) do
    data
    |> Map.keys()
    |> List.first()
    |> case do
      nil ->
        users

      name ->
        case join_or_leave do
          :join -> MapSet.put(users, User.new(name))
          :leave -> MapSet.delete(users, User.new(name))
        end
    end
  end
end
