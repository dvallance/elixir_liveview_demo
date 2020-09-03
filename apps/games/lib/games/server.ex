defmodule Games.Server do
  defstruct [:name, :game, :created_by]

  # module is a game type that has a `new`
  def new(%Games.User{} = user, module) do
    %Games.Server{
      name: user.name,
      created_by: user,
      game: module.new(user)
    }
  end

  @doc """
    Updates the servers `:game` value.
  """
  def update_game(server, func) when is_function(func) do
    %Games.Server{server | game: func.(server.game)}
  end

  def update_game(server, game) do
    %Games.Server{server | game: game}
  end

  def subscribe(%Games.Server{} = server) do
    Phoenix.PubSub.subscribe(Games.PubSub, channel(server))
  end

  def unsubscribe(%Games.Server{} = server) do
    Phoenix.PubSub.unsubscribe(Games.PubSub, channel(server))
  end

  @doc """
    Broadcasts out the latest server data via PubSub.
  """
  def broadcast(%Games.Server{} = server) do
    :ok = Phoenix.PubSub.broadcast(Games.PubSub, channel(server), server)
    server
  end

  # Gets the PubSub topic/channel for a specific server, which is the name of
  # the server.
  defp channel(%Games.Server{} = server) do
    "game_server:#{server.name}"
  end
end
