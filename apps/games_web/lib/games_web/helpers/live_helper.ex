defmodule GamesWeb.LiveHelper do
  @moduledoc """
  Shared methods for LiveView use.
  """
  import Phoenix.LiveView, only: [assign: 3]

  @doc """
  Assigns `:current_user` from the session to the live view socket.
  """
  def assign_current_user(socket, session) do
    assign(socket, :current_user, user_from_session(session))
  end

  @doc """
  Retrieves the current_user from the session.
  """
  def user_from_session(session) do
    session["current_user"]
  end

  @doc """
  Get the users name from the socket.
  """
  def current_user(%Phoenix.LiveView.Socket{} = socket) do
    socket.assigns.current_user
  end
end
