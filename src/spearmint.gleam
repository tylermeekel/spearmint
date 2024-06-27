import app/router
import app/web
import gleam/erlang/os
import gleam/erlang/process
import gleam/pgo
import gleam/result
import mist
import wisp

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  // Get config result from loading environment variables
  let config_result =
    os.get_env("POSTGRES_URL")
    |> result.map(pgo.url_config)
    |> result.flatten()

  // Panic if config did not load properly, create config otherwise
  let config = case config_result {
    Ok(config) -> config
    Error(_) ->
      panic as "Failed to create config from Postgres URL. Make sure the POSTGRES_URL environment variable is set properly."
  }

  // Connect to database and configure context
  let db = pgo.connect(config)
  let context = web.Context(db)

  // Create handler for requests that wraps the given context.
  let handler = router.handle_request(_, context)
  let assert Ok(_) =
    wisp.mist_handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
