import gleam/pgo
import wisp.{type Request, type Response}

pub type Context {
  Context(db: pgo.Connection)
}

pub fn middleware(req: Request, next: fn(Request) -> Response) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  next(req)
}
