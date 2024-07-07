import antigone
import gleam/bit_array
import gleam/dynamic
import gleam/list
import gleam/pgo
import util/responses
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
  next: fn() -> Response,
) -> Response {
  let queries = wisp.get_query(req)
  let filtered_queries =
    list.filter(queries, fn(item: #(String, String)) -> Bool {
      case item.0 {
        "api_token" -> True
        "application_id" -> True
        _ -> False
      }
    })

  case filtered_queries {
    [#("api_token", api_token), #("application_id", application_id)]
    | [#("api_token", api_token), #("application_id", application_id)] -> {
      case check_authenticated(api_token, application_id, db) {
        True -> next()
        False ->
          responses.unauthorized_request("Invalid API token or application ID")
      }
    }
    _ -> responses.unauthorized_request("Missing API token or application ID")
  }
}

fn check_authenticated(
  api_key: String,
  application_id: String,
  db: pgo.Connection,
) -> Bool {
  let query =
    "SELECT application_id::text, key FROM api_key WHERE application_id = $1"

  case
    pgo.execute(
      query,
      db,
      [pgo.text(application_id)],
      dynamic.tuple2(dynamic.string, dynamic.string),
    )
  {
    Ok(response) -> {
      case response.rows {
        [#(_, hashed_key), ..] -> {
          let api_key_bitarray = bit_array.from_string(api_key)
          antigone.verify(api_key_bitarray, hashed_key)
        }
        _ -> False
      }
    }
    Error(_) -> False
  }
}
