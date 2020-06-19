# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

config :games_web,
  generators: [context_app: :games]

# Configures the endpoint
config :games_web, GamesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "HNSwFGnAFKWcqp9Oci7XosHUu+3so+r3H5XbM9/7n+MB58s5l3ro/lasn/EwfU4E",
  render_errors: [view: GamesWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Games.PubSub,
  live_view: [signing_salt: "FCQJpeM3"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
