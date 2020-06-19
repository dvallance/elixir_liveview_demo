defmodule GamesWeb.LoggedInPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opt) do
    case Plug.Conn.get_session(conn, :current_user) do
      nil ->
        conn
        |> Phoenix.Controller.redirect(to: "/authentication/login")
        |> Plug.Conn.halt()

      _current_user ->
        conn
    end
  end
end
