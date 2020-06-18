defmodule Games.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Games.PubSub}
      # Start a worker by calling: Games.Worker.start_link(arg)
      # {Games.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Games.Supervisor)
  end
end
