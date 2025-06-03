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
            "properties" => {
              "id" => {"type" => "string"},
              "kind" => {"enum" => ["string"], "type" => "string"},
            },
            "required" => ["id"],
            "type" => "object",
          },
          {
            "properties" => {
              "id" => {"type" => "integer"},
              "kind" => {"enum" => ["integer"], "type" => "string"},
            },
            "required" => ["id"],
            "type" => "object",
          },
        ]
      )
    end

    it "renders switch schemas" do
      schema =
        Datacaster.schema do
          switch('kind').
            on(:string, {id: string}).
            on(:integer, {id: integer}).
            on(:uuid, {id: uuid}).
            else({id: boolean})

        end

      expect(schema.to_json_schema).to eq(
        "oneOf" => [
          {
            "properties" => {
              "id" => {"type" => "string"},
              "kind" => {"enum" => ["string"], "type" => "string"},
            },
            "required" => ["id"],
            "type" => "object",
          },
          {
            "properties" => {
              "id" => {"type" => "integer"},
              "kind" => {"enum" => ["integer"], "type" => "string"},
            },
            "required" => ["id"],
            "type" => "object",
          },
          {
            "properties" => {
              "id" => {"pattern" => "/\\A\\h{8}-\\h{4}-\\h{4}-\\h{4}-\\h{12}\\z/", "type" => "string"},
              "kind" => {"enum" => ["uuid"], "type" => "string"},
            },
            "required" => ["id"],
            "type" => "object",
          },
          {
            "properties" => {"id" => {"type" => "boolean"}},
            "required" => ["id"],
            "type" => "object",
          },
        ]
      )
    end

    it "renders complex switch schemas" do
      schema =
        Datacaster.schema do
          extract_string = transform_to_hash(
            rest_string: pick(:string)
          )

          extract_integer = transform_to_hash(
            rest_integer: pick(:integer)
          )

          extract_schema =
            switch('kind').
              on(:string, extract_string).
              on(:integer, extract_integer).
              else(pass)

          base_schema = switch('kind').
            on(:string, { kind: compare('string'), rest_string: string, other_string: string }).
            on(:integer, { kind: compare('integer'), rets_integer: integer, other_integer: string }).
            on(:none, { kind: compare('none'), rest_none: string })

          extract_schema & base_schema
        end

      expect(schema.to_json_schema).to eq(
        "oneOf" => [
          {
            "properties" => {
              "kind" => {"enum" => ["string"], "type" => "string"},
              "other_string" => {"type" => "string"},
              "string" => {"type" => "string"},
            },
            "required" => ["kind", "other_string", "string"],
            "type" => "object",
          },
          {
            "properties" => {
              "integer" => {},
              "kind" => {"enum" => ["integer"], "type" => "string"},
              "other_integer" => {"type" => "string"},
              "rets_integer" => {"type" => "integer"},
            },
            "required" => ["kind", "rets_integer", "other_integer"],
            "type" => "object",
          },
          {
            "properties" => {
              "kind" => {"enum" => ["none"], "type" => "string"},
              "rest_none" => {"type" => "string"},
            },
            "required" => ["kind", "rest_none"],
            "type" => "object",
          },
        ]
      )
    end

    it 'renders schemas with many to one remapping' do
      schema =
        Datacaster.schema do
          transform_to_hash(
            rest_string: pick(:string1, :string2) & transform(&:first)
          ) & hash_schema(
            rest_string: string
          )
        end

      expect(schema.to_json_schema).to eq({
       "properties" => {
         "string1"=>{},
         "string2"=>{},
       },
       "required" => [],
        "type"=>"object",
      })
    end

    it 'render schemas with transform_to_hash and hash_schema' do
      schema =
        Datacaster.schema do
          transform_to_hash(
            rest_string: pick(:string)
          ) & hash_schema(
            rest_string: string
          )
        end

      expect(schema.to_json_schema).to eq({
        "properties" => {
          "string"=>{ "type"=>"string" },
        },
        "required" => ["string"],
        "type"=>"object",
      })
    end

    it 'render transform_to_hash without pick' do
      schema =
        Datacaster.schema do
          transform_to_hash(
            rest_string: transform { |x| '' }
          ) & hash_schema(
            rest_string: string
          )
        end

      expect(schema.to_json_schema).to eq({
        "properties" => {},
        "required" => [],
        "type"=>"object",
      })
    end

    it "renders schemas with hash_schema with default" do
      schema =
        Datacaster.schema do
          hash_schema(
            username: optional(string) & default('Unknown')
              .json_schema(description: 'The username of the user'),
            email: pattern(/@/).json_schema(description: 'The email of the user')
          )
        end

      expect(schema.to_json_schema).to eq(
        "type" => "object",
        "properties" => {
          "username" => {
            'description' => 'The username of the user',
            "type"=>"string"
          },
          "email" => {
            "description" => "The email of the user",
            "type" => "string",
            "pattern" => "/@/"
          },
        },
        "required" => %w(email)
      )
    end

    it "renders schemas with optional(...)" do
      schema =
        Datacaster.schema do
          optional(string)
        end

      expect(schema.to_json_schema).to eq(
        {
          "type"=>"string"
        },
      )
    end

    it "renders schemas with default(...)" do
      schema =
        Datacaster.schema do
          optional(string) & default('Unknown')
        end

      expect(schema.to_json_schema).to eq(
        {
          "type"=>"string"
        },
      )
    end

    it "renders schemas with compare(nil)" do
      schema =
        Datacaster.schema do
          compare(nil) | compare('sdf')
        end

      expect(schema.to_json_schema).to eq(
        {
          "anyOf" => [
            { "type" => "null" },
            { "enum"=>["sdf"] },
          ]
        },
      )
    end

    it "renders schemas with array" do
      schema =
        Datacaster.schema do
          array_of(compare(nil) | compare('sdf'))
        end

      expect(schema.to_json_schema).to eq(
        {
          "items" => {
            "anyOf"=>[
              { "type" => "null" },
              { "enum"=>["sdf"] },
            ],
          },
          "type" => "array",
        },
      )
    end

    it "renders hash schemas with array" do
      schema =
        Datacaster.schema do
          hash_schema(
            test: array_of(compare(nil) | compare('sdf'))
          )
        end

      expect(schema.to_json_schema).to eq(
        {
          "properties" => {"test"=>{"items"=>{"anyOf"=>[{ "type" => "null" }, {"enum"=>["sdf"]}]}, "type"=>"array"}},
          "required" => ["test"],
          "type" => "object",
        },
      )
    end

    it "renders to_integer" do
      schema =
        Datacaster.schema do
          to_integer
        end

      expect(schema.to_json_schema).to eq(
        {
          "oneOf" => [{"type"=>"string"}, {"type"=>"number"}]
        },
      )
    end

    it "renders numeric" do
      schema =
        Datacaster.schema do
          numeric
        end

      expect(schema.to_json_schema).to eq(
        {
          "oneOf" => [{"type"=>"string"}, {"type"=>"number"}]
        },
      )
    end

    it "renders uuid" do
      schema =
        Datacaster.schema do
          uuid
        end

      expect(schema.to_json_schema).to eq(
        {
          "type"=>"string",
          "pattern" => "/\\A\\h{8}-\\h{4}-\\h{4}-\\h{4}-\\h{12}\\z/"
        },
      )
    end

    it "renders array_of(uuid)" do
      schema =
        Datacaster.schema do
          array_of(uuid)
        end

      expect(schema.to_json_schema).to eq({
       "items" => {"pattern"=>"/\\A\\h{8}-\\h{4}-\\h{4}-\\h{4}-\\h{12}\\z/", "type"=>"string"},
       "type" => "array",
      })
    end

    it "renders compare(nil) | array_of(uuid)" do
      schema =
        Datacaster.schema do
          compare(nil) | array_of(uuid)
        end

      expect(schema.to_json_schema).to eq({
       "anyOf" => [
         { "type" => "null" },
         {"items"=>{"pattern"=>"/\\A\\h{8}-\\h{4}-\\h{4}-\\h{4}-\\h{12}\\z/", "type"=>"string"}, "type"=>"array"},
       ],
      })
    end

    it "renders array & array_of(uuid)" do
      schema =
        Datacaster.schema do
          array & array_of(uuid)
        end

      expect(schema.to_json_schema).to eq({
       "items" => {"pattern"=>"/\\A\\h{8}-\\h{4}-\\h{4}-\\h{4}-\\h{12}\\z/", "type"=>"string"},
       "type" => "array",
      })
    end

    it "renders pick & some validation" do
      schema =
        Datacaster.schema do
          pick(:a, :b) & transform { 'a' } & included_in(['a'])
        end

      expect(schema.to_json_schema).to eq({
        "properties" => {"a"=>{}, "b"=>{}},
        "type" => "object",
      })
    end

    it "renders single pick & some validation" do
      schema =
        Datacaster.schema do
          pick(:a) & included_in(['a'])
        end

      expect(schema.to_json_schema).to eq({
        "properties" => {"a"=>{"enum"=>["a"]}},
        "type" => "object",
      })
    end
  end
end
