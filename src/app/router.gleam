import app/web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, context: web.Context) -> Response {
  wisp.ok()
}
