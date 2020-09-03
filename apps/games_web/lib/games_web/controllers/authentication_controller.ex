defmodule GamesWeb.AuthenticationController do
  use GamesWeb, :controller
  alias GamesWeb.SessionHelper

  @doc """
  Handles rendering the login form.
  """
  def login(conn, _params) do
    render(conn, "login.html")
  end

  @doc """
  Handles loging out by removing the `current_user` from the session and
  redirecting to the login form.
  """
  def log_out(conn, _params) do
    conn
    |> SessionHelper.delete_current_user()
    |> redirect(to: Routes.authentication_path(conn, :login))
  end

  @doc """
  Handles logging in, which validates the username requested and checks to see
  if it is already in use.

  Will render errors on name validation, or name already in use.
  """
  def log_in(conn, %{"name" => name} = _params) do
    with {:ok, name} <- clean_name(name),
         :ok <- validate_length_of_name(name),
         :ok <- available_name(name) do
      conn
      |> SessionHelper.add_current_user(name)
      |> redirect(to: Routes.demo_path(conn, :games))
    else
      {:error, msg} ->
        conn
        |> put_flash(:error, msg)
        |> render(:login)
    end
  end

  # Trim whitespace from name.
  defp clean_name(name), do: {:ok, String.trim(name)}

  # Defines a required character count for a name. 
  defp validate_length_of_name(name) do
    name
    |> String.length()
    |> case do
      length when length >= 3 -> :ok
      _ -> {:error, "Please provide a longer name"}
    end
  end

  # Determines if a name is available for use. Meaning it's not currently found
  # in `Presence` or in a temporary cache.
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

  # Checks the `reserved_names` cache for a specific name.
  defp cached_name?(name) do
    case Cachex.exists?(:reserved_names, name) do
      {:ok, true} -> true
      {:ok, false} -> false
    end
  end

  # Checks `Presence` for the existense of a name.
  defp presence_of_name?(name) do
    GamesWeb.Presence.list(Games.Chat.global_chat())
    |> Map.has_key?(name)
  end
end
