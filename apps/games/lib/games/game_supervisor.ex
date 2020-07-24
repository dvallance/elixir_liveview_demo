defmodule Games.GameSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    # Adding max_children to protect the demo server from to much load.
    DynamicSupervisor.init(max_children: 1, strategy: :one_for_one)
  end

  def start(game_type, %Games.User{} = user) when is_binary(game_type) do
    DynamicSupervisor.start_child(__MODULE__, {game_type(game_type), user})
  end

  def state_of_all_game_servers() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      :sys.get_state(pid)
    end)
  end

  @doc """
  Returns the first game found that has the user's name in the players list.
  """
  def game_server_for_user(%Games.User{} = user) do
    Enum.find(state_of_all_game_servers(), fn %{game: game} ->
      Enum.member?(Map.keys(game.players), user)
    end)
  end

  def game_server_state("pig", %Games.User{} = user) do
    :sys.get_state(Games.PigServer.via(user))
  end

  @doc """
  Given a string representing a game type this function returns the 
  corresponding module.
  """
  defp game_type("pig"), do: Games.PigServer
  defp game_type(_), do: {:error, :unkown_game_type}
end
