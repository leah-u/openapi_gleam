import decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}

pub const server_url = ""

// Client

pub type ApiResult(a, b) {
  Success(a)
  Failure(b)
  DecodeError
}

pub type Pet {
  Pet(id: Int, name: String, tag: Option(String))
}

pub type MyError {
  MyError(code: Int, message: Int)
}

pub fn pet_decoder() -> decode.Decoder(Pet) {
  decode.into({
    use id <- decode.parameter
    use name <- decode.parameter
    use tag <- decode.parameter
    Pet(id:, name:, tag:)
  })
  |> decode.field("id", decode.int)
  |> decode.field("name", decode.string)
  |> decode.field("tag", decode.optional(decode.string))
}

pub fn pets_decoder() -> decode.Decoder(List(Pet)) {
  decode.list(pet_decoder())
}

/// List all pets
/// 
/// limit: How many items to return at one time (max 100)
pub fn list_pets(limit limit: Option(Int)) -> Result(Request(String), Nil) {
  let request =
    request.new()
    |> request.set_host(server_url)
    |> request.set_method(http.Get)
    |> request.set_path("/pets")

  let request = case limit {
    Some(limit) ->
      request.set_query(request, [#("limit", int.to_string(limit))])
    None -> request
  }

  Ok(request)
}

pub fn decode_list_pets_response(
  response: Response(String),
) -> ApiResult(List(Pet), MyError) {
  case response.status {
    200 -> {
      let res =
        json.decode(response.body, fn(json) {
          decode.list(pet_decoder()) |> decode.from(json)
        })
      case res {
        Ok(pets) -> Success(pets)
        Error(_) -> DecodeError
      }
    }
    _ -> Failure(MyError(0, 0))
  }
}
