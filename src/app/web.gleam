import gleam/dynamic
import gleam/list
import gleam/pgo
import wisp.{type Request, type Response}

pub type Context {
  Context(db: pgo.Connection)
}

pub fn middleware(
  req: Request,
  context: Context,
  next: fn(Request, Context) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  next(req, context)
}

pub fn authenticate(
  req: Request,
  db: pgo.Connection,
  next: fn(String) -> Response,
) -> Response {
  case
    wisp.get_query(req)
    |> list.key_find(find: "api_token")
  {
    Ok(api_token) ->
      case get_application_id(api_token, db) {
        Ok(application_id) -> {
          next(application_id)
        }
        Error(_) -> wisp.bad_request()
      }
    Error(_) -> wisp.bad_request()
  }
}

fn get_application_id(
  api_key: String,
  db: pgo.Connection,
) -> Result(String, Nil) {
  let query =
    "SELECT application_id::text, key::text FROM api_key WHERE key = $1"

  case
    pgo.execute(
      query,
      db,
      [pgo.text(api_key)],
      dynamic.tuple2(dynamic.string, dynamic.string),
    )
  {
    Ok(response) -> {
      case response.rows {
        [#(application_id, _), ..] -> Ok(application_id)
        _ -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}
