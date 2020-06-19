defmodule GamesWeb.Presence do
  use Phoenix.Presence,
    otp_app: :games_web,
    pubsub_server: Games.PubSub
end
