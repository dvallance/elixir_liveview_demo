defmodule Games.GameSupervisor do
  @moduledoc """
  A DynamicSupervisor responsible for managing active games.
  """

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    # Adding max_children to protect the demo server from to much load.
    DynamicSupervisor.init(max_children: 25, strategy: :one_for_one)
  end

  @doc """
  Starts a new game server based on the type as a string. Currently only "pig"
  is available.
  """
  def start(game_type, %Games.User{} = user) when is_binary(game_type) do
    DynamicSupervisor.start_child(__MODULE__, {game_type(game_type), user})
  end

  @doc """
  Retrieves a list of game state, for all the currently running games. 

  Note: `which_children` can cause an out of memory exception if we were dealing
  with a large number of children, but isn't an issue for the demo.
  """
  def state_of_all_game_servers() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      :sys.get_state(pid)
    end)
  end

  @doc """
  Stop one of the game servers by it's pid.
  """
  def stop(nil), do: :ok
  def stop(pid), do: DynamicSupervisor.terminate_child(__MODULE__, pid)

  @doc """
  Returns the first game found that has the user's name in the players list.
  """
  def game_server_for_user(%Games.User{} = user) do
    Enum.find(state_of_all_game_servers(), fn %{game: game} ->
      Enum.member?(Map.keys(game.players), user)
    end)
  end

  @doc """
  Server state for a game of pig.
  """
  def game_server_state("pig", %Games.User{} = user) do
    :sys.get_state(Games.PigServer.via(user))
  end

  # Given a string representing a game type this function returns the 
  # corresponding module.
  defp game_type("pig"), do: Games.PigServer
  defp game_type(_), do: {:error, :unkown_game_type}
end
