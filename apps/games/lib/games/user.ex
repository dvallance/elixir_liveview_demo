defmodule Games.User do
  @moduledoc """
  A struct to represent a user.
  """

  # Keeping it simple for this demo app.
  defstruct [:name]

  @typedoc """
  User data type. 
  """
  @type t :: %__MODULE__{
          name: String.t()
        }

  @doc """
  Safe way to create a user `t:t/0`.
  """
  def new(%Games.User{} = user), do: user
  def new(user) when is_map(user), do: struct(Games.User, user)
  def new(name), do: %Games.User{name: name}
end
