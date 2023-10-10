RSpec.describe Datacaster do
  include Dry::Monads[:result]

  before(:all) do
    @i18n_module = Datacaster::Config.i18n_module
    Datacaster::Config.i18n_module = Datacaster::SubstituteI18n
  end

  after(:all) do
    Datacaster::Config.i18n_module = @i18n_module
  end

  describe "#to_json_schema" do
    it "renders simple hash schemas" do
      schema =
        Datacaster.schema do
          hash_schema(
            id: integer.json_schema(description: 'The ID of the user'),
            email: string.json_schema(description: 'The email of the user')
          )
        end

        expect(schema.to_json_schema).to eq(
          "type" => "object",
          "properties" => {
            "id" => {
              "description" => "The ID of the user",
              "type" => "integer"
            },
            "email" => {
              "description" => "The email of the user",
              "type" => "string"
            }
          },
          "required" => %w(id email)
        )
    end

    it "renders pattern and included_in casters" do
      schema =
        Datacaster.schema do
          hash_schema(
            id: integer & included_in([1, 2, 3]).json_schema(description: 'The ID of the user'),
            email: pattern(/@/).json_schema(description: 'The email of the user')
          )
        end

      expect(schema.to_json_schema).to eq(
        "type" => "object",
        "properties" => {
          "id" => {
            "description" => "The ID of the user",
            "type" => "integer",
            "enum" => [1, 2, 3]
          },
          "email" => {
            "description" => "The email of the user",
            "type" => "string",
            "pattern" => "/@/"
          },
        },
        "required" => %w(id email)
      )
    end

    it "renders complex hash-array schemas" do
      schema =
        Datacaster.schema do
          hash_schema(
            id: integer,
          ) & hash_schema(
            email: pattern(/@/),
            document_ids: array_of(integer)
          )
        end

      expect(schema.to_json_schema).to eq(
        "type" => "object",
        "properties" => {
          "id" => {
            "type" => "integer",
          },
          "email" => {
            "type" => "string",
            "pattern" => "/@/"
          },
          "document_ids" => {
            "type" => "array",
            "items" => {
              "type" => "integer"
            }
          }
        },
        "required" => %w(id email document_ids)
      )
    end

    it "renders OR (|) schemas" do
      schema =
        Datacaster.schema do
          hash_schema(
            id: integer | string,
          )
        end

      expect(schema.to_json_schema).to eq(
        "type" => "object",
        "properties" => {
          "id" => {
            "anyOf" => [
              {"type" => "integer"},
              {"type" => "string"}
            ]
          },
        },
        "required" => %w(id)
      )
    end

    it "renders requirements to incoming hash for hash mapper" do
      schema =
        Datacaster.schema do
          transform_to_hash(
            id: pick(:test) & integer
          )
        end

      expect(schema.to_json_schema).to eq(
        "type" => "object",
        "properties" => {
          "test" => {
            "type" => "integer"
          },
        }
      )
    end

    it "renders pick schemas" do
      schema =
        Datacaster.schema do
          pick(:test) & integer
        end
      expect(schema.to_json_schema).to eq(
        "type" => "object",
        "properties" => {
          "test" => {
            "type" => "integer"
          },
        }
      )
    end

    it "renders if-then-else schemas" do
      schema =
        Datacaster.schema do
          integer.
            then(integer32).
            else(string & included_in(%w(1 2)))
        end
      expect(schema.to_json_schema).to eq(
        "oneOf" => [
          {
            "type" => "integer",
            "format" => "int32"
          },
          {
            "not" => {"type" => "integer"},
            "type" => "string",
            "enum" => %w(1 2)
          }
        ]
      )
    end

    it "renders switch schemas" do
      schema =
        Datacaster.schema do
          switch('kind').
            on('string', {id: string}).
            on('integer', {id: integer})
        end
      expect(schema.to_json_schema).to eq(
        "oneOf" => [
          {
            "type" => "object",
            "properties" => {
              "kind" => {
                "enum" => ['string']
              },
              "id" => {
                "type" => "string"
              }
            },
            "required" => %w(id)
          },
          {
            "type" => "object",
            "properties" => {
              "kind" => {
                "enum" => ['integer']
              },
              "id" => {
                "type" => "integer"
              }
            },
            "required" => %w(id)
          }
        ]
      )
    end

    it "renders schemas with default(...)"
    it "renders schemas with optional(...)"
  end
end
