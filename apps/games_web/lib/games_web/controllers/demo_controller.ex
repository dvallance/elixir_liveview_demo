defmodule GamesWeb.DemoController do
  use GamesWeb, :controller

  @doc """
  Handles rendering the game related views.
  """
  def games(conn, _params) do
    render(conn, "games.html")
  end
end
