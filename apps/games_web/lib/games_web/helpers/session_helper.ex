defmodule GamesWeb.SessionHelper do
  @moduledoc """
  Place to put helper fuctions for working with the session.
  """

  @current_user :current_user

  import Plug.Conn, only: [get_session: 2, put_session: 3, delete_session: 2]

  def delete_current_user(%Plug.Conn{} = conn) do
    delete_session(conn, @current_user)
  end

  def add_current_user(%Plug.Conn{} = conn, name) when is_binary(name) do
    put_session(conn, @current_user, Games.User.new(name))
  end

  def current_user(%Plug.Conn{} = conn) do
    get_session(conn, @current_user)
  end
end
