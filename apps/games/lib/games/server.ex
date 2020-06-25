defmodule Games.Server do
  defstruct [:name, :game]

  def update_game(server, game) do
    %Games.Server{server | game: game}
  end

  def subscribe(%Games.Server{} = server) do
    Phoenix.PubSub.subscribe(Games.PubSub, channel(server))
  end

  def broadcast(%Games.Server{} = server) do
    Phoenix.PubSub.broadcast(Games.PubSub, channel(server), server)
  end

  defp channel(%Games.Server{} = server) do
    "game_server:#{server.name}"
  end
end
