import app/web
import gleam/dynamic
import gleam/http.{Get, Post}
import gleam/io
import gleam/json
import gleam/list
import gleam/pgo
import types/types
import wisp.{type Request, type Response}

pub fn handle_api(req: Request, context: web.Context) -> Response {
  let assert ["api", ..rest] = wisp.path_segments(req)
  case rest {
    ["applications"] -> handle_applications(req, context)
    _ -> wisp.not_found()
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
    Error(e) -> {
      io.debug(e)
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
        Error(execute_error) -> {
          io.debug(execute_error)
          wisp.internal_server_error()
        }
      }
    }
    Error(decode_error) -> {
      io.debug(decode_error)
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
