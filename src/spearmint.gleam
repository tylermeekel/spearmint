import app/router
import app/web
import gleam/erlang/os
import gleam/erlang/process
import gleam/io
import gleam/pgo
import mist
import wisp

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let postgres_url = case os.get_env("POSTGRES_URL") {
    Ok(url) -> url
    Error(_) -> panic as "The POSTGRES_URL environment variable is not set."
  }

  let config = case pgo.url_config(postgres_url) {
    Ok(config) -> pgo.Config(..config, pool_size: 2)
    Error(_) ->
      panic as "The POSTGRES_URL variable is not a valid URL, please check the format. For now, the port is also a requirement (default: 5432)."
  }

  io.debug(config)

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
