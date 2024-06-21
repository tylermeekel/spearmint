import app/web
import gleam/http.{Get}
import gleam/json
import types/types.{Person}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)
  use <- wisp.require_method(req, Get)

  let people = [
    Person(name: "Tommy", age: 112, description: "A person"),
    Person(name: "Bob", age: 112, description: "A person"),
  ]

  json.array(people, types.encode_person)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
