import gleam/dynamic
import gleam/option.{type Option, None, Some}
import gleam/pgo
import wisp.{type Request, type Response}

pub type Context {
  Context(db: pgo.Connection, application_id: Option(String))
}

pub fn middleware(
  req: Request,
  context: Context,
  next: fn(Request, Context) -> Response,
) -> Response {
  use json <- wisp.require_json(req)
  let api_key_decoder = dynamic.field("api_key", dynamic.string)

  let context = case api_key_decoder(json) {
    Ok(api_key) -> {
      let query = "SELECT application_id::text FROM api_key WHERE key = $1"

      let return_type = dynamic.string

      case pgo.execute(query, context.db, [pgo.text(api_key)], return_type) {
        Ok(result) -> {
          case result.rows {
            [application_id] ->
              Context(..context, application_id: Some(application_id))
            _ -> context
          }
        }
        _ -> context
      }
    }

    Error(_) -> Context(..context, application_id: None)
  }

  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  next(req, context)
}
