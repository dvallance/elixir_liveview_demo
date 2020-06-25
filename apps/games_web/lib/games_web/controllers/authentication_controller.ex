defmodule GamesWeb.AuthenticationController do
  use GamesWeb, :controller
  alias GamesWeb.SessionHelper

  def login(conn, _params) do
    render(conn, "login.html")
  end

  def log_out(conn, _params) do
    conn
    |> SessionHelper.delete_current_user()
    |> redirect(to: Routes.authentication_path(conn, :login))
  end

  def log_in(conn, %{"name" => name} = _params) do
    with {:ok, name} <- clean_name(name),
         :ok <- validate_length_of_name(name),
         :ok <- available_name(name) do
      conn
      |> SessionHelper.add_current_user(name)
      |> redirect(to: Routes.game_path(conn, :index))
    else
      {:error, msg} ->
        conn
        |> put_flash(:error, msg)
        |> render(:login)
    end
  end

  defp clean_name(name), do: {:ok, String.trim(name)}

  defp validate_length_of_name(name) do
    name
    |> String.length()
    |> case do
      length when length >= 3 -> :ok
      _ -> {:error, "Please provide a longer name"}
    end
  end

  defp available_name(name) do
    if !cached_name?(name) && !presence_of_name?(name) do
      # Reserve the name for 5 seconds to allow time for the this user to end up
      # being tracked by presence.
      Cachex.put(:reserved_names, name, :reserved)
      Cachex.expire(:reserved_names, name, :timer.seconds(5))
      :ok
    else
      {:error, "Sorry. The name you wanted is currently in use."}
    end
  end

  defp cached_name?(name) do
    case Cachex.exists?(:reserved_names, name) do
      {:ok, true} -> true
      {:ok, false} -> false
    end
  end

  defp presence_of_name?(name) do
    GamesWeb.Presence.list(Games.Chat.global_chat())
    |> Map.has_key?(name)
  end
end
