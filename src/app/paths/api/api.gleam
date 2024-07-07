import antigone
import app/web
import gleam/bit_array
import gleam/dynamic
import gleam/http.{Get, Post}
import gleam/json
import gleam/list
import gleam/pgo
import ids/uuid
import types/types
import wisp.{type Request, type Response}

pub fn handle_api(req: Request, context: web.Context) -> Response {
  let assert ["api", ..rest] = wisp.path_segments(req)
  case rest {
    ["applications"] -> handle_applications(req, context)
    ["api_keys"] -> handle_api_keys(req, context)
    ["test"] -> handle_test(req, context)
    _ -> wisp.not_found()
  }
}

fn handle_test(req: Request, context: web.Context) -> Response {
  use <- web.authenticate(req, context.db)

  wisp.ok()
}

fn handle_api_keys(req: Request, context: web.Context) -> Response {
  case req.method {
    Post -> post_new_api_key(req, context)
    _ -> wisp.method_not_allowed([Post])
  }
}

type ApplicationIdType {
  ApplicationIdType(application_id: String)
}

// TODO: fix, this is hard to read.
fn post_new_api_key(req: Request, context: web.Context) -> Response {
  use json <- wisp.require_json(req)

  let decoder =
    dynamic.decode1(
      ApplicationIdType,
      dynamic.field("application_id", dynamic.string),
    )

  case decoder(json) {
    Ok(ApplicationIdType(application_id)) -> {
      let assert Ok(uuid) = uuid.generate_v4()
      let hashed =
        bit_array.from_string(uuid)
        |> antigone.hash(antigone.hasher(), _)

      let query =
        "INSERT INTO api_key (key, application_id) VALUES ($1, $2) RETURNING key, application_id::text"

      let dynamic_type = dynamic.tuple2(dynamic.string, dynamic.string)

      case
        pgo.execute(
          query,
          context.db,
          [pgo.text(hashed), pgo.text(application_id)],
          dynamic_type,
        )
      {
        Ok(response) -> {
          case response.rows {
            [#(_, application_id), ..] -> {
              let json_string =
                json.to_string_builder(
                  json.object([
                    #("key", json.string(uuid)),
                    #("application_id", json.string(application_id)),
                  ]),
                )

              wisp.json_response(json_string, 201)
            }
            _ -> wisp.internal_server_error()
          }
        }
        Error(_) -> {
          wisp.internal_server_error()
        }
      }
    }
    Error(_) -> {
      wisp.internal_server_error()
    }
  }
}

fn handle_applications(req: Request, context: web.Context) -> Response {
  case req.method {
    Get -> get_all_applications(context)
    Post -> post_new_application(req, context)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn get_all_applications(context: web.Context) -> Response {
  let query = "SELECT id::text, name, owner_id::text FROM application"

  let dynamic_type =
    dynamic.tuple3(
      dynamic.string,
      // ID
      dynamic.string,
      // Name
      dynamic.string,
      // Owner ID
    )

  case pgo.execute(query, context.db, [], dynamic_type) {
    Ok(response) -> {
      // Send response as JSON
      application_rows_to_list(response.rows)
      |> json.array(types.encode_application)
      |> json.to_string_builder()
      |> wisp.json_response(200)
    }
    Error(_) -> {
      wisp.internal_server_error()
    }
  }
}

fn post_new_application(req: Request, context: web.Context) -> Response {
  use json <- wisp.require_json(req)

  let decoder = dynamic.field("name", dynamic.string)

  case decoder(json) {
    Ok(name) -> {
      let query =
        "INSERT INTO application (name) VALUES ($1) RETURNING id::text, name, owner_id::text"

      let dynamic_type =
        dynamic.tuple3(
          dynamic.string,
          // ID
          dynamic.string,
          // Name
          dynamic.string,
          // Owner ID
        )

      case pgo.execute(query, context.db, [pgo.text(name)], dynamic_type) {
        Ok(response) -> {
          // Send response as JSON
          case application_rows_to_list(response.rows) {
            [first] -> {
              types.encode_application(first)
              |> json.to_string_builder()
              |> wisp.json_response(201)
            }
            // This should never happen, unless there is an issue with the Postgres request,
            // which should result in the Error case anyways.
            _ -> wisp.internal_server_error()
          }
        }
        Error(_) -> {
          wisp.internal_server_error()
        }
      }
    }
    Error(_) -> {
      wisp.bad_request()
    }
  }
}

fn application_rows_to_list(
  rows: List(#(String, String, String)),
) -> List(types.Application) {
  list.map(rows, fn(row) -> types.Application {
    types.Application(row.0, row.1, row.2)
  })
}
