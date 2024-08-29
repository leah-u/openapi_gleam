import argv
import decode
import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/function
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set
import simplifile

pub fn main() {
  case argv.load().arguments {
    [openapi_file] -> {
      io.println("Opening file `" <> openapi_file <> "`")
      let assert Ok(json) = simplifile.read(openapi_file)
      let assert Ok(document) = json.decode(json, decode) |> io.debug
      codegen(document)
      Nil
    }
    _ -> {
      io.println_error("Please specify an OpenApi file")
      exit(1)
    }
  }
}

pub type OpenApiDocument {
  OpenApiDocument(
    /// The OpenAPI version number of this document.
    openapi_version: String,
    /// Metadata about this API.
    info: OpenApiInfo,
    /// A list of Server Objects, which provide connectivity information to a target server.
    servers: List(OpenApiServer),
    // paths: 
    /// An element to hold various schemas for the document.
    components: OpenApiComponents,
  )
}

fn document_decoder() {
  decode.into({
    use openapi_version <- decode.parameter
    use info <- decode.parameter
    use servers <- decode.parameter
    use components <- decode.parameter
    OpenApiDocument(openapi_version:, info:, servers:, components:)
  })
  |> decode.field("openapi", decode.string)
  |> decode.field("info", info_decoder())
  |> decode.field("servers", decode.list(server_decoder()))
  |> decode.field("components", components_decoder())
}

/// The available paths and operations for the API.
pub type OpenApiInfo {
  OpenApiInfo(
    /// The title of the API.
    title: String,
    /// A short summary of the API.
    summary: Option(String),
    /// A description of the API.
    description: Option(String),
    /// A URL to the Terms of Service for the API in the form of a URL.
    terms_of_service: Option(String),
    ///	The contact information for the exposed API.
    contact: Option(OpenApiContact),
    /// The license information for the exposed API.
    license: Option(OpenApiLicense),
    /// The version of the OpenAPI document (which is distinct from the OpenAPI
    /// Specification version or the API implementation version).
    version: String,
  )
}

fn info_decoder() {
  decode.into({
    use title <- decode.parameter
    use summary <- decode.parameter
    use description <- decode.parameter
    use terms_of_service <- decode.parameter
    use contact <- decode.parameter
    use license <- decode.parameter
    use version <- decode.parameter
    OpenApiInfo(
      title:,
      summary:,
      description:,
      terms_of_service:,
      contact:,
      license:,
      version:,
    )
  })
  |> decode.field("title", decode.string)
  |> decode.field("summary", decode.optional(decode.string))
  |> decode.field("description", decode.optional(decode.string))
  |> decode.field("termsOfService", decode.optional(decode.string))
  |> decode.field("contact", decode.optional(contact_decoder()))
  |> decode.field("license", decode.optional(license_decoder()))
  |> decode.field("version", decode.string)
}

pub type OpenApiContact {
  OpenApiContact(
    /// The identifying name of the contact person/organization.
    name: Option(String),
    /// The URL pointing to the contact information.
    url: Option(String),
    /// The email address of the contact person/organization.
    email: Option(String),
  )
}

fn contact_decoder() {
  decode.into({
    use name <- decode.parameter
    use url <- decode.parameter
    use email <- decode.parameter
    OpenApiContact(name:, url:, email:)
  })
  |> decode.field("name", decode.optional(decode.string))
  |> decode.field("url", decode.optional(decode.string))
  |> decode.field("email", decode.optional(decode.string))
}

pub type OpenApiLicense {
  OpenApiLicense(
    /// The license name used for the API.
    name: String,
  )
  OpenApiLicenseWithIdentifier(
    /// The license name used for the API.
    name: String,
    /// An SPDX license expression for the API.
    identifier: String,
  )
  OpenApiLicenseWithUrl(
    /// The license name used for the API.
    name: String,
    /// A URL to the license used for the API.
    url: String,
  )
}

fn license_decoder() {
  decode.into({
    use name <- decode.parameter
    use identifier <- decode.parameter
    use url <- decode.parameter
    case identifier, url {
      _, Some(url) -> OpenApiLicenseWithUrl(name:, url:)
      Some(identifier), _ -> OpenApiLicenseWithIdentifier(name:, identifier:)
      None, None -> OpenApiLicense(name:)
    }
  })
  |> decode.field("name", decode.string)
  |> decode.field("identifier", decode.optional(decode.string))
  |> decode.field("url", decode.optional(decode.string))
}

pub type OpenApiServer {
  OpenApiServer(
    /// A URL to the target host.
    url: String,
    /// An optional string describing the host designated by the URL.
    description: Option(String),
    // variables 	Map[string, Server Variable Object] 	A map between a variable name and its value. The value is used for substitution in the server's URL template.
  )
}

fn server_decoder() {
  decode.into({
    use url <- decode.parameter
    use description <- decode.parameter
    OpenApiServer(url:, description:)
  })
  |> decode.field("url", decode.string)
  |> decode.field("description", decode.optional(decode.string))
}

pub type OpenApiComponents {
  OpenApiComponents(schemas: dict.Dict(String, OpenApiSchema))
}

fn components_decoder() {
  decode.into({
    use schemas <- decode.parameter
    OpenApiComponents(schemas:)
  })
  |> decode.field("schemas", decode.dict(decode.string, schema_decoder()))
}

pub type OpenApiSchema {
  Object(properties: dict.Dict(String, OpenApiSchema))
  String
  Integer
  Optional(type_: OpenApiSchema)
  Reference(path: String)
  Array(type_: OpenApiSchema)
}

fn schema_decoder() -> decode.Decoder(OpenApiSchema) {
  decode.one_of([
    decode.into({
      use type_ <- decode.parameter
      type_
    })
      |> decode.field("type", decode.string)
      |> decode.then(fn(type_) {
        case type_ {
          "object" -> object_decoder()
          "integer" -> decode.into(Integer)
          "string" -> decode.into(String)
          "array" -> array_decoder()
          _ -> decode.fail("invalid type: `" <> type_ <> "`")
        }
      }),
    decode.into({
      use path <- decode.parameter
      Reference(path:)
    })
      |> decode.field("$ref", decode.string),
  ])
}

fn object_decoder() -> decode.Decoder(OpenApiSchema) {
  decode.into({
    use required <- decode.parameter
    use properties <- decode.parameter

    let required =
      required
      |> option.unwrap([])
      |> set.from_list

    let properties =
      properties
      |> dict.map_values(fn(name, type_) {
        case set.contains(required, name) {
          True -> type_
          False -> Optional(type_)
        }
      })

    Object(properties:)
  })
  |> decode.field("required", decode.optional(decode.list(decode.string)))
  |> decode.field("properties", decode.dict(decode.string, schema_decoder()))
}

fn array_decoder() -> decode.Decoder(OpenApiSchema) {
  decode.into({
    use type_ <- decode.parameter
    Array(type_:)
  })
  |> decode.field("items", schema_decoder())
}

pub fn decode(
  json: Dynamic,
) -> Result(OpenApiDocument, List(dynamic.DecodeError)) {
  decode.from(document_decoder(), json)
}

fn type_name(of type_: OpenApiSchema, in document: OpenApiDocument) -> String {
  case type_ {
    Integer -> "Int"
    String -> "String"
    Optional(type_:) -> "Option(" <> type_name(of: type_, in: document) <> ")"
    Array(type_:) -> "List(" <> type_name(of: type_, in: document) <> ")"
    Object(properties:) -> todo
    Reference(path:) -> todo
  }
}

pub fn codegen(document: OpenApiDocument) {
  let types =
    document.components.schemas
    |> dict.to_list
    |> list.filter_map(fn(schema) {
      let #(name, type_) = schema
      case type_ {
        Object(properties) -> {
          let out = "pub type " <> name <> " {\n  " <> name <> "("
          let properties_amount = dict.size(properties)
          let out =
            dict.to_list(properties)
            |> list.index_fold(out, fn(out, property, index) {
              let #(name, type_) = property
              let out =
                out <> name <> ": " <> type_name(in: document, of: type_)
              case index < properties_amount - 1 {
                True -> out <> ", "
                False -> out
              }
            })
          let out = out <> ")\n}"
          Ok(out)
        }
        _ -> Error(Nil)
      }
    })

  let code = "import gleam/option.{type Option}"
  let code = list.fold(types, code, fn(code, type_) { code <> "\n\n" <> type_ })

  list.each(types, io.println)
  simplifile.write(to: "./src/petstore_gen.gleam", contents: code)
}

@external(erlang, "openapi_ffi", "exit")
pub fn exit(n: Int) -> Nil
