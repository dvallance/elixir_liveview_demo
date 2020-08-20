defmodule Games.PigServer do
  use GenServer
  alias Games.ComputerOpponent

  @type opponent :: %Games.ComputerOpponent{} | %Games.User{}

  # time to wait for rolling to complete.
  @rolled_delay 2000

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

  def cast(%Games.Server{} = server, term) do
    GenServer.cast(via(server), term)
  end

  def handle_cast({:assign_opponent, user, opponent}, %Games.Server{} = server) do
    server = Games.Server.update_game(server, Games.Pig.assign_opponent(server.game, opponent))

    unless match?(%Games.ComputerOpponent{}, opponent) do
      # Broadcast to global chat the invite for the user.
      Games.Chat.game_invite(user, opponent)
    end

    Games.Server.broadcast(server)

    {:noreply, server}
  end

  def handle_cast({:lock_in_points, player}, %Games.Server{} = server) do
    server =
      Games.Pig.lock_in_points(server.game, player)
      |> update_game_server(server)

    {:noreply, server}
  end

  def handle_cast({:reset, _user}, %Games.Server{} = server) do
    server = Games.Server.update_game(server, Games.Pig.new(server.created_by))
    Games.Server.broadcast(server)

    {:noreply, server}
  end

  # def handle_cast({:roll, user}, _from, %Games.Server{} = server) do
  #  case roll(server, user) do
  #    {:ok, server} -> {:reply, {:ok, server}, server}
  #    error -> {:reply, error, server}
  #  end
  # end

  # TODO fix this up
  def handle_cast({:roll, user}, %Games.Server{} = server) do
    case roll(server, user) do
      {:ok, server} -> {:noreply, server}
      error -> {:noreply, server}
    end
  end

  defp roll(server, user) do
    with {:ok, pig} <- Games.Pig.roll(server.game, user),
         server <- Games.Server.update_game(server, pig),
         server <- Games.Server.broadcast(server),
         timer_ref <- Process.send_after(self(), {:rolled, user}, @rolled_delay) do
      {:ok, server}
    else
      error -> error
    end
  end

  def handle_info({:rolled, user}, %Games.Server{} = server) do
    server =
      Games.Pig.rolled(server.game, user)
      |> update_game_server(server)

    {:noreply, server}
  end

  defp update_game_server(%Games.Pig{} = pig, %Games.Server{} = server) do
    Games.Server.update_game(server, pig)
    |> Games.Server.broadcast()
    |> Games.Server.update_game(&subsequent_action/1)
  end

  # When the game is finished theres no need for any more action.
  defp subsequent_action(%Games.Pig{turn: :finished} = pig), do: pig

  # When the turn is undecided roll for computer player. 
  defp subsequent_action(%Games.Pig{turn: :undecided} = pig) do
    computer_action(pig, fn opponent ->
      GenServer.cast(self(), {:roll, opponent})
    end)
  end

  defp subsequent_action(%Games.Pig{turn: player_turn} = pig) do
    computer_action(pig, fn opponent ->
      if Games.Pig.players_turn?(pig, opponent) do
        computers_turn(pig, opponent)
      end
    end)
  end

  defp computer_action(%Games.Pig{} = pig, function) do
    computer_opponent = get_computer_opponent(pig)
    if computer_opponent, do: function.(computer_opponent)
    pig
  end

  def computers_turn(pig, opponent) do
    player_data = Map.get(pig.players, opponent)

    if player_data.points > 0 do
      # decide to lock in points or roll
      Enum.random(1..6)
      |> case do
        1 -> GenServer.cast(self(), {:lock_in_points, opponent})
        _ -> GenServer.cast(self(), {:roll, opponent})
      end
    else
      GenServer.cast(self(), {:roll, opponent})
    end
  end

  defp get_computer_opponent(%Games.Pig{} = pig) do
    Enum.find(Map.keys(pig.players), &match?(%ComputerOpponent{}, &1))
  end
end
