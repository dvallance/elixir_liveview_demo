defmodule Games.PigServer do
  use GenServer

  @type opponent :: %Games.ComputerOpponent{} | %Games.User{}

  @impl true
  @doc """
  A server is created by a specific player and uses the players name to
  identify itself (since for this demo the players name is uniq).
  """
  def init(%Games.User{} = user) do
    {:ok, Games.Server.new(user, Games.Pig)}
  end

  def start_link(%Games.User{} = user) do
    GenServer.start_link(__MODULE__, user, name: via(user))
  end

  @doc """
  Used to name PigServer(s) by a server_name with the `:via`
  option.
  """
  def via(%Games.Server{} = server) do
    {:via, Registry, {Games.Registry, server.name}}
  end

  def via(%Games.User{} = user) do
    {:via, Registry, {Games.Registry, user.name}}
  end

  @spec assign_opponent(%Games.Server{}, opponent) :: {:ok, %Games.User{}}
  def assign_opponent(%Games.Server{} = server, opponent) do
    GenServer.call(via(server), {:assign_opponent, opponent})
  end

  def reset(%Games.Server{} = server) do
    GenServer.call(via(server), :reset)
  end

  def roll(%Games.Server{} = server, %Games.User{} = user) do
    GenServer.call(via(server), {:roll, user})
  end

  def rolled(%Games.Server{} = server, user_name, rolled) do
    GenServer.call(via(server), {:rolled, user_name, rolled})
  end

  def handle_call({:assign_opponent, opponent}, _from, %Games.Server{} = server) do
    server = Games.Server.update_game(server, Games.Pig.assign_opponent(server.game, opponent))
    Games.Server.broadcast(server)
    {:reply, {:ok, server}, server}
  end

  def handle_call(:reset, _from, %Games.Server{} = server) do
    server = Games.Server.update_game(server, Games.Pig.new(server.created_by))

    Games.Server.broadcast(server)
    {:reply, {:ok, server}, server}
  end

  def handle_call({:roll, %Games.User{} = user}, _from, %Games.Server{} = server) do
    server = Games.Server.update_game(server, Games.Pig.roll(server.game, user))
    Games.Server.broadcast(server)
    {:reply, {:ok, server}, server}
  end

  def handle_call({:rolled, user_name, rolled}, _from, %Games.Server{} = server) do
    server = Games.Server.update_game(server, Games.Pig.rolled(server.game, user_name, rolled))
    Games.Server.broadcast(server)
    {:reply, {:ok, server}, server}
  end
end
