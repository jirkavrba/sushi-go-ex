import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sushi_go, SushiGoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "aKlSMNKA0O6+qH5fO78WaFfHniWsOf/fBORhIkn/oA7u5eoeSMn7BUvMIdX/MAKi",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
