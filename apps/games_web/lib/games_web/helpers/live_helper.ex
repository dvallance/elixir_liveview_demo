defmodule GamesWeb.LiveHelper do
  import Phoenix.LiveView, only: [assign: 3]

  @moduledoc """
  Shared methods for LiveView use.
  """
  def assign_current_user(socket, session) do
    assign(socket, :current_user, user_from_session(session))
  end

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
