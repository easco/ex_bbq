# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.Project.config[:target]}.exs"

# if unset, the default regulatory domain is the world domain, "00"
config :nerves_interim_wifi,
  regulatory_domain: "US"

config :bbq_ui, BbqUi.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "iQV3hOrGWmVz9QOeKNeUjBhzMX0L61tDHKofei8CrDpk6ICMVDnd3Itgey651dsL",
  render_errors: [view: BbqUi.ErrorView, accepts: ~w(html json)],
  pubsub: [name: BbqUi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"