defmodule GamesWeb.DemoController do
  use GamesWeb, :controller

  def games(conn, _params) do
    render(conn, "games.html")
  end
end
