defmodule Games.PigServer do
  use GenServer

  @type opponent :: %Games.ComputerOpponent{} | %Games.User{}

  @impl true
  @doc """
  A server is created by a specific player and uses the players name to
  identify itself (since for this demo the players name is uniq).
  """
  def init(%Games.User{} = user) do
    {:ok,
     %Games.Server{
       name: user.name,
       game: Games.Pig.new(user)
     }}
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

  def roll_for_first_turn(%Games.Server{} = server, %Games.User{} = user) do
    GenServer.call(via(server), {:roll_for_first_turn, user})
  end

  def handle_call({:assign_opponent, opponent}, _from, %Games.Server{} = server) do
    server = Games.Server.update_game(server, Games.Pig.assign_opponent(server.game, opponent))
    Games.Server.broadcast(server)
    {:reply, {:ok, server}, server}
  end

  def handle_call({:roll_for_first_turn, %Games.User{} = user}, _from, %Games.Server{} = server) do
    server = Games.Server.update_game(server, Games.Pig.roll_for_first_turn(server.game, user))
    Games.Server.broadcast(server)
    {:reply, {:ok, server}, server}
  end
end
