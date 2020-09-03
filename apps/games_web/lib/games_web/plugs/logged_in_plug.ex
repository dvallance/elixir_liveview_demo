defmodule GamesWeb.LoggedInPlug do
  import Plug.Conn, only: [get_session: 2, halt: 1]

  def init(options), do: options

  @doc """
  A Plug to redirect to the login page if the `current_user` is not available
  in the session.
  """
  def call(conn, _opt) do
    case get_session(conn, :current_user) do
      nil ->
        conn
        |> Phoenix.Controller.redirect(to: "/authentication/login")
        |> halt()

      _current_user ->
        conn
    end
  end
end
