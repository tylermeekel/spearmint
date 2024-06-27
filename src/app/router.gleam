import app/web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, context: web.Context) -> Response {
  use _req <- web.middleware(req)
  
  case wisp.path_segments(req) {
    ["users"] -> wisp.ok()
    _ -> wisp.not_found()
  }
}
