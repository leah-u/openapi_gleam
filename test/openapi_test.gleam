import gleam/dict
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import openapi
import simplifile

pub fn main() {
  gleeunit.main()
}

pub fn petstore_parse_test() {
  simplifile.read("petstore.json")
  |> should.be_ok
  |> json.decode(openapi.decode)
  |> should.be_ok
  |> should.equal(openapi.OpenApiDocument(
    openapi_version: "3.0.0",
    info: openapi.OpenApiInfo(
      title: "Swagger Petstore",
      summary: None,
      license: Some(openapi.OpenApiLicense(name: "MIT")),
      contact: None,
      description: None,
      terms_of_service: None,
      version: "1.0.0",
    ),
    servers: [
      openapi.OpenApiServer(
        url: "http://petstore.swagger.io/v1",
        description: None,
      ),
    ],
    components: openapi.OpenApiComponents(
      dict.from_list([
        #(
          "Error",
          openapi.Object(
            dict.from_list([
              #("code", openapi.Integer),
              #("message", openapi.String),
            ]),
          ),
        ),
        #(
          "Pet",
          openapi.Object(
            dict.from_list([
              #("id", openapi.Integer),
              #("name", openapi.String),
              #("tag", openapi.Optional(openapi.String)),
            ]),
          ),
        ),
        #("Pets", openapi.Array(openapi.Reference("#/components/schemas/Pet"))),
      ]),
    ),
  ))
}
