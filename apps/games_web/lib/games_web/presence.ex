defmodule GamesWeb.Presence do
  use Phoenix.Presence,
    otp_app: :games_web,
    pubsub_server: Games.PubSub

  alias Games.User

  def retrieve_users_from_presence() do
    GamesWeb.Presence.list(Games.Chat.global_chat())
    |> Map.keys()
    |> Enum.map(&User.new/1)
    |> MapSet.new()
  end
end
