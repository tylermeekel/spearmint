import gleam/json
import wisp.{type Response}

pub fn unauthorized_request(message: String) -> Response {
  // Build JSON
  let obj =
    json.object([#("message", json.string("Request Unauthorized: " <> message))])
    |> json.to_string_builder()

  wisp.json_response(obj, 401)
}
