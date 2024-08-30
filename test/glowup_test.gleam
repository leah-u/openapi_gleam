import gleam/dict
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import glowup
import simplifile

pub fn main() {
  gleeunit.main()
}

pub fn petstore_parse_test() {
  simplifile.read("petstore.json")
  |> should.be_ok
  |> json.decode(glowup.decode)
  |> should.be_ok
  |> should.equal(glowup.OpenApiDocument(
    openapi_version: "3.0.0",
    info: glowup.OpenApiInfo(
      title: "Swagger Petstore",
      summary: None,
      license: Some(glowup.OpenApiLicense(name: "MIT")),
      contact: None,
      description: None,
      terms_of_service: None,
      version: "1.0.0",
    ),
    servers: [
      glowup.OpenApiServer(
        url: "http://petstore.swagger.io/v1",
        description: None,
      ),
    ],
    components: glowup.OpenApiComponents(
      dict.from_list([
        #(
          "Error",
          glowup.Object(
            dict.from_list([
              #("code", glowup.Integer),
              #("message", glowup.String),
            ]),
          ),
        ),
        #(
          "Pet",
          glowup.Object(
            dict.from_list([
              #("id", glowup.Integer),
              #("name", glowup.String),
              #("tag", glowup.Optional(glowup.String)),
            ]),
          ),
        ),
        #("Pets", glowup.Array(glowup.Reference("#/components/schemas/Pet"))),
      ]),
    ),
  ))
}
