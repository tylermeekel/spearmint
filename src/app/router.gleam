import app/paths/api/api
import app/web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, context: web.Context) -> Response {
  use _req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["api", ..] -> api.handle_api(req, context)
    _ -> wisp.not_found()
  }
}
