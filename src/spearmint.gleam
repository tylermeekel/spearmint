import app/router
import app/web
import gleam/erlang/os
import gleam/erlang/process
import gleam/pgo
import gleam/result
import mist
import wisp
import gleam/io
import gleam/uri.{Uri}
import gleam/option

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let postgres_url = case os.get_env("POSTGRES_URL") {
    Ok(url) -> url
    Error(_) -> panic as "POSTGRES_URL environment variable is not set."
  }

  // Parse Postgres URL
  let parsed_uri = case uri.parse(postgres_url) {
    Ok(uri) -> uri
    Error(_) -> panic as "Failed to parse Postgres URL."
  }

  io.debug(parsed_uri)

  // Connect to database and configure context
  let db = pgo.connect(pgo.default_config())
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
