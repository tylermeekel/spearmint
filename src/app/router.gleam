import app/paths/api/api
import app/web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, context: web.Context) -> Response {
  use req, context <- web.middleware(req, context)

  case wisp.path_segments(req) {
    ["api", ..] -> api.handle_api(req, context)
    _ -> wisp.not_found()
  }
}
