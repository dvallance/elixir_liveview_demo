defmodule GamesWeb.ChatLive do
  @moduledoc """
  LiveView for global chat feature.
  """
  use GamesWeb, :live_view
  alias Games.User
  import GamesWeb.LiveHelper

  @impl true
  def render(assigns) do
    Phoenix.View.render(GamesWeb.ChatView, "chat.html", assigns)
  end

  @impl true
  @doc """
  Loads all messages from our message store, and all users from Presence so we
  can display global chat messages and show which users are logged in.
  """
  def mount(_params, session, socket) do
    if connected?(socket) do
      Games.Chat.subscribe(:global)
      track_user_by_presence(session)
    end

    socket =
      socket
      |> assign(:messages, Games.Chat.Message.all())
      |> assign(:users, GamesWeb.Presence.retrieve_users_from_presence())
      |> assign_current_user(session)

    {:ok, socket}
  end

  @impl true
  @doc """
  Handles posting of messages from our frontend form.
  """
  def handle_event("post_message", %{"chat" => %{"text" => text}} = _params, socket) do
    Games.Chat.global_text_message(socket.assigns.current_user, text)

    {:noreply, socket}
  end

  @impl true
  @doc """
  Handler for global chat PubSub broadcasts.
  """
  def handle_info(%Games.Chat.Message{} = message, socket) do
    socket = update(socket, :messages, &[message | &1])

    {:noreply, socket}
  end

  @impl true
  @doc """
  Handles GamesWeb.Presence messages, which has a payload of the joining and
  leaving users.
  """
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

  # Sets up this LiveView socket as the representation of the current user
  # in the global chat topic, using the current user as the key, and the current
  # user data structure, as the meta.
  defp track_user_by_presence(session) do
    GamesWeb.Presence.track(
      self(),
      Games.Chat.global_chat(),
      user_from_session(session).name,
      user_from_session(session)
    )
  end

  # Adds or removes users based on "presence_diff" data, so they can be added
  # to the socket and be seen joining or leaving the chat.
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
