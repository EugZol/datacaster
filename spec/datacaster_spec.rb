 RSpec.describe Datacaster do
  include Dry::Monads[:result]

  describe "any typecasting" do
    subject { described_class.schema { any } }

    it "passes anything" do
      expect(subject.("test").to_dry_result).to eq Success("test")
      expect(subject.(nil).to_dry_result).to eq Success(nil)
    end

    it "returns Failure on Absent" do
      expect(subject.(Datacaster.absent).to_dry_result).to eq Failure(["must be set"])
    end
  end

  describe "string typecasting" do
    subject { described_class.schema { string } }

    it "passes strings" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "returns Failure on integeres" do
      expect(subject.(1).to_dry_result).to eq Failure(["must be string"])
    end

    it "returns Failure on nils" do
      expect(subject.(nil).to_dry_result).to eq Failure(["must be string"])
    end

    it "passes empty strings" do
      expect(subject.("").to_dry_result).to eq Success("")
    end
  end

  describe "non-empty string typecasting" do
    subject { described_class.schema { non_empty_string } }

    it "passes strings" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "returns Failure on integeres" do
      expect(subject.(1).to_dry_result).to eq Failure(["must be string"])
    end

    it "returns Failure on empty strings" do
      expect(subject.("").to_dry_result).to eq Failure(["must be present"])
    end
  end

  describe "decimal typecasting" do
    subject { described_class.schema { decimal } }

    it "converts strings" do
      expect(subject.("100.12345678").to_dry_result).to eq Success(BigDecimal("100.12345678"))
    end

    it "converts floats" do
      expect(subject.(1.234).to_dry_result).to eq Success(BigDecimal("1.23400000"))
    end

    it "returns Failure on nils" do
      expect(subject.(nil).to_dry_result).to eq Failure(["must be decimal"])
    end
  end

  describe "integer32 typecasting" do
    subject { described_class.schema { integer32 } }

    it "passes 32-bit integers" do
      expect(subject.(2_147_483_647).to_dry_result).to eq Success(2_147_483_647)
    end

    it "returns Failure on non-integers" do
      expect(subject.("100").to_dry_result).to eq Failure(["must be integer"])
    end

    it "returns Failure on too big integers" do
      expect(subject.(2_147_483_648).to_dry_result).to eq Failure(["out of range"])
    end
  end

  describe "optional string typecasting" do
    subject { described_class.schema { optional(string) } }

    it "passes strings" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "returns Failure on integeres" do
      expect(subject.(1).to_dry_result).to eq Failure(["must be string"])
    end

    it "returns Failure on nils" do
      expect(subject.(nil).to_dry_result).to eq Failure(["must be string"])
    end

    it "passes empty strings" do
      expect(subject.("").to_dry_result).to eq Success("")
    end

    it "isn't added to hash values if absent, passed values otherwise" do
      schema = described_class.schema { hash_schema(title: optional(string)) }

      expect(schema.(title: "test").to_dry_result).to eq Success({title: "test"})
      expect(schema.({}).to_dry_result).to eq Success({})
    end
  end

  describe "string optional param typecasting" do
    subject { described_class.schema { optional_param(string) } }

    it "passes strings" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "returns failure with integers" do
      expect(subject.(1).to_dry_result).to eq Failure(["must be string"])
    end

    it "returns failure with nils" do
      expect(subject.(nil).to_dry_result).to eq Failure(["must be string"])
    end

    it "treats empty string as absent (yields Absent)" do
      expect(subject.("").to_dry_result).to eq Success(Datacaster.absent)
    end

    it "passes Absent (yields Absent)" do
      expect(subject.(Datacaster.absent).to_dry_result).to eq Success(Datacaster.absent)
    end

    it "isn't added to hash values if absent, passes values otherwise" do
      schema = described_class.partial_schema { hash_schema(title: optional_param(string)) }

      expect(schema.(title: "test").to_dry_result).to eq Success({title: "test"})
      expect(schema.(title: nil).to_dry_result).to eq Failure({title: ["must be string"]})
      expect(schema.(test: 123).to_dry_result).to eq Success({test: 123})
      expect(schema.(test: 123, title: "").to_dry_result).to eq Success({test: 123})
    end
  end

  describe "to_integer typecasting" do
    subject { described_class.schema { to_integer } }

    it "passes integers" do
      expect(subject.(1).to_dry_result).to eq Success(1)
    end

    it "typecasts strings" do
      expect(subject.("1").to_dry_result).to eq Success(1)
    end

    it "returns Failure on nil" do
      expect(subject.(nil).to_dry_result).to eq Failure(["must be integer"])
    end

    it "returns Failure on empty string" do
      expect(subject.("").to_dry_result).to eq Failure(["must be integer"])
    end

    it "returns Failure when unable to coerce" do
      expect(subject.("no number").to_dry_result).to eq Failure(["must be integer"])
    end
  end

  describe "to_float typecasting" do
    subject { described_class.schema { to_float } }

    it "passes floats" do
      expect(subject.(1.5).to_dry_result).to eq Success(1.5)
    end

    it "typecasts strings" do
      expect(subject.("1.25").to_dry_result).to eq Success(1.25)
    end

    it "returns Failure on nil" do
      expect(subject.(nil).to_dry_result).to eq Failure(["must be float"])
    end

    it "returns Failure on empty string" do
      expect(subject.("").to_dry_result).to eq Failure(["must be float"])
    end

    it "returns Failure when unable to coerce" do
      expect(subject.("no number").to_dry_result).to eq Failure(["must be float"])
    end
  end

  describe "to_boolean typecasting" do
    subject { described_class.schema { to_boolean } }

    it "passes booleans" do
      expect(subject.(true).to_dry_result).to eq Success(true)
      expect(subject.(false).to_dry_result).to eq Success(false)
    end

    it "typecasts strings" do
      expect(subject.("true").to_dry_result).to eq Success(true)
      expect(subject.("1").to_dry_result).to eq Success(true)

      expect(subject.("false").to_dry_result).to eq Success(false)
      expect(subject.("0").to_dry_result).to eq Success(false)
    end

    it "returns Failure on nil" do
      expect(subject.(nil).to_dry_result).to eq Failure(["must be boolean"])
    end

    it "returns Failure when unable to coerce" do
      expect(subject.("not a boolean").to_dry_result).to eq Failure(["must be boolean"])
    end
  end

  describe "iso8601 typecasting" do
    subject { described_class.schema { iso8601 } }

    it "treats strings as iso8601 date-time" do
      expect(subject.("2019-03-01T12:30:20Z").to_dry_result).to eq Success(DateTime.parse("2019-03-01T12:30:20Z"))
    end

    it "returns Failure when unable to coerce" do
      expect(subject.("2019-03-01T12:70:20Z").to_dry_result).to eq Failure(["must be iso8601 string"])
    end
  end

  describe "hash typecasting" do
    it "passes hash values" do
      params = {"a" => 1, "b" => "test"}

      expect(described_class.schema { hash_value }.(params).to_dry_result).to eq Success({"a" => 1, "b" => "test"})
    end
  end

  describe "hash schema typecasting" do
    it "casts all fields" do
      type = described_class.schema { hash_schema("a" => to_integer, "b" => to_float) }

      expect(type.({"a" => "1", "b" => "2.35"}).to_dry_result).to eq Success({"a" => 1, "b" => 2.35})
    end

    it "fails on nils" do
      type = described_class.schema { hash_schema(a: integer, b: float) }

      expect(type.(nil).to_dry_result).to eq Failure(["must be hash"])
    end

    it "fails on empty strings" do
      type = described_class.schema { hash_schema(a: to_integer, b: to_float) }

      expect(type.("").to_dry_result).to eq Failure(["must be hash"])
    end

    it "returns failure if additional fields present" do
      type = described_class.schema { hash_schema(a: to_integer, b: to_float) }

      expect(type.({a: "1", b: "2.35", c: "other", d: 1234}).to_dry_result).to eq \
        Failure({c: ["must be absent"], d: ["must be absent"]})
    end

    it "aggregates Failures among fields" do
      type = described_class.schema { hash_schema(a: to_integer, b: to_boolean) }

      expect(type.({a: "not a number", b: "not a boolean"}).to_dry_result).to eq \
        Failure(a: ["must be integer"], b: ["must be boolean"])
    end

    it "removes unaccepted keys with hash_schema" do
      params = {
        name: "test",
        email: "test@email"
      }

      subject = Datacaster.choosy_schema do
        hash_schema(
          user_info: any
        )
      end

      expect(subject.(params).to_dry_result).to eq Failure(user_info: ["must be set"])
    end
  end

  describe "and (&) node" do
    subject do
      described_class.schema { string & compare("test") }
    end

    it "returns Success when both are valid" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "returns left Failure, when left is Failure" do
      expect(subject.(:not_even_string).to_dry_result).to eq Failure(["must be string"])
    end

    it "returns right Failure, when left is Success and right is Failure" do
      expect(subject.("not_test").to_dry_result).to eq Failure(['must be equal to "test"'])
    end
  end

  describe "or (|) node" do
    subject do
      described_class.schema { string | integer }
    end

    it "returns Success when left is valid" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "returns Success when right is valid" do
      expect(subject.(5).to_dry_result).to eq Success(5)
    end

    it "returns right Failure, when both are Failure" do
      expect(subject.(:a_symbol).to_dry_result).to eq Failure(["must be integer"])
    end
  end

  describe "and with failure aggregation (*) node" do
    subject do
      described_class.schema { hash_schema(a: string) * hash_schema(b: integer) }
    end

    it "returns Success when both are valid" do
      expect(subject.({a: "test", b: 5}).to_dry_result).to eq Success({a: "test", b: 5})
    end

    it "returns left Failure when only left is Failure" do
      expect(subject.({a: :not_string, b: 5}).to_dry_result).to eq Failure({a: ["must be string"]})
    end

    it "returns right Failure when only right is Failure" do
      expect(subject.({a: "test", b: :not_integer}).to_dry_result).to eq Failure({b: ["must be integer"]})
    end

    it "returns aggregated failures when both are Failure" do
      expect(subject.({a: :not_string, b: :not_integer}).to_dry_result).to eq \
        Failure({a: ["must be string"], b: ["must be integer"]})
    end
  end

  describe "then (.then.else) node" do
    subject do
      described_class.schema { string.then(compare("test")).else(integer) }
    end

    it "returns 'else' Success, if left is Failure and 'else' is Success" do
      expect(subject.(5).to_dry_result).to eq Success(5)
    end

    it "returns 'else' Failure, if left is Failure and 'else' is Failure" do
      expect(subject.(:not_string).to_dry_result).to eq Failure(["must be integer"])
    end

    it "returns 'then' Success, if left is Success and 'then' is Success" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    # N.B.: "a & b | c" would return "c" here, instead of "b's Failure"
    # That's the reason we need then-else as separate node
    it "returns 'then' Failure, if left is Success and 'then' is Failure" do
      expect(subject.("5").to_dry_result).to eq Failure(['must be equal to "test"'])
    end

    it "raises error on double 'else'" do
      expect { described_class.schema { string.then(compare("test")).else(integer).else(string) } }.to \
        raise_error(ArgumentError)
    end

    it "raises error when 'else' is omitted " do
      type = described_class.schema { string.then(compare("test")) }
      expect { type.("test") }.to raise_error(ArgumentError)
    end
  end

  describe "active model validations" do
    require 'datacaster/validator'

    subject do
      described_class.schema { integer & validate(numericality: {greater_than_or_equal_to: 18}) }
    end

    it "returns Success if AM validation passes" do
      expect(subject.(18).to_dry_result).to eq Success(18)
    end

    it "returns validation errors as Failure if AM validation fails" do
      expect(subject.(17).to_dry_result).to eq Failure(["must be greater than or equal to 18"])
    end
  end

  describe "hash schema composition" do
    subject do
      type_field_partial =
        described_class.partial_schema do
          hash_schema(
            type: string & transform_if_present(&:downcase) & validate(inclusion: {in: %w(person entity)})
          )
        end

      person_qualifier = described_class.partial_schema do
        hash_schema(type: compare("person"))
      end

      person_schema = described_class.partial_schema do
        hash_schema(
          name: string,
          dob: iso8601
        )
      end

      entity_schema = described_class.partial_schema do
        hash_schema(
          title: string,
          id: integer
        )
      end

      common_schema = described_class.partial_schema do
        hash_schema(
          details: optional(string),
          comment: string
        )
      end

      # One way to read/understand this:
      #
      # PROCESS WITH type_file_partial,
      # PASS THE RESULT TO (common_schema JOINLY PROCESSED/VALIDATED WITH
      #   (
      #     IF person_qualifier THEN person_schema ELSE entity_schema
      #   )
      # )
      described_class.schema do
        type_field_partial &
          common_schema * (person_qualifier.then(person_schema).else(entity_schema))
      end
    end

    it "processes composition (&, *, |, +, .then.else)" do
      params = {
        type: "Person",
        name: "John Smith",
        dob: "1980-01-01",
        details: "",
        comment: "Trader"
      }

      expect(subject.(params).to_dry_result).to eq Success({
        type: "person",
        name: "John Smith",
        dob: DateTime.parse("1980-01-01"),
        details: "",
        comment: "Trader"
      })
    end

    it "aggregates Failures" do
      params = {
        type: "unknown",
        name: "John Smith",
        dob: "1980-01-01",
        details: "",
        comment: 1
      }

      expect(subject.(params).to_dry_result).to eq Failure(type: ["is not included in the list"])

      params = {
        type: "Person",
        name: nil,
        dob: "1980-01-01",
        details: "123",
        comment: nil
      }

      expect(subject.(params).to_dry_result).to eq Failure(name: ["must be string"], comment: ["must be string"])
    end
  end

  describe "hash schema DSL" do
    subject do
      Datacaster.schema do
        type_validation = hash_schema(
          type: string & transform_if_present(&:downcase) & validate(inclusion: {in: %w(person entity)})
        )

        person_qualifier = hash_schema(
          type: compare("person")
        )

        common_fields = hash_schema(
          details: optional_param(string),
          comment: string
        )

        person_fields = hash_schema(
          name: string,
          dob: iso8601
        )

        entity_fields = hash_schema(
          title: string,
          id: integer
        )

        type_validation & common_fields * (person_qualifier.then(person_fields).else(entity_fields))
      end
    end

    it "processes complex schemas" do
      params = {
        type: "Person",
        name: "John Smith",
        dob: "1980-01-01",
        comment: "Trader"
      }

      expect(subject.(params).to_dry_result).to eq Success({
        type: "person",
        name: "John Smith",
        dob: DateTime.parse("1980-01-01"),
        comment: "Trader"
      })

      params = {
        type: "Entity",
        title: "Trade LLC",
        id: 5,
        name: "John Smith",
        dob: "1980-01-01",
        details: "validated",
        comment: "Trader company"
      }

      expect(subject.(params).to_dry_result).to eq Failure({
        name: ["must be absent"],
        dob: ["must be absent"]
      })

      params = {
        type: "Entity",
        title: "Trade LLC",
        id: 5,
        details: "validated",
        comment: "Trader company"
      }

      expect(subject.(params).to_dry_result).to eq Success({
        type: "entity",
        title: "Trade LLC",
        id: 5,
        details: "validated",
        comment: "Trader company"
      })

      params = {
        type: "Person",
        name: nil,
        dob: "1980-01-01",
        details: "123",
        comment: nil
      }

      expect(subject.(params).to_dry_result).to eq Failure(name: ["must be string"], comment: ["must be string"])
    end
  end

  describe "array typecasting" do
    it "passes array values" do
      params = [1, 2, 3, "something"]

      expect(described_class.schema { array }.(params).to_dry_result).to eq Success([1, 2, 3, "something"])
    end
  end

  describe "array schema typecasting" do
    subject { described_class.schema { array_schema(integer) } }

    it "validates each member" do
      expect(subject.([1, 2, 3]).to_dry_result).to eq Success([1, 2, 3])
      expect(subject.([1, "something", 3, "anything"]).to_dry_result).to eq Failure(
        1 => ["must be integer"],
        3 => ["must be integer"]
      )
    end

    it "fails on empty array" do
      # empty arrays could be checked with "compare([])" if needed
      expect(subject.([]).to_dry_result).to eq Failure(["must not be empty"])
    end
  end

  describe "recursive schemas" do
    it "process hash inside of hash" do
      schema = described_class.schema do
        hash_schema(
          title: string,
          owner: {
            name: string,
            title: string & validate(inclusion: {in: %w(director CEO)})
          }
        )
      end

      params = {
        title: "Some LLC",
        owner: {
          name: "John Smith",
          title: "CEO"
        }
      }

      expect(schema.(params).to_dry_result).to eq Success({
        title: "Some LLC",
        owner: {
          name: "John Smith",
          title: "CEO"
        }
      })

      #

      params = {
        # title - absent,
        owner: {
          name: "John Smith",
          title: "CFO"
        }
      }

      expect(schema.(params).to_dry_result).to eq Failure({
        title: ["must be string"],
        owner: {
          title: ["is not included in the list"]
        }
      })

      #

      params = {
        title: "Some LLC",
        owner: {
          name: "John Smith",
          title: "CEO"
        }
      }

      expect(schema.(params).to_dry_result).to eq Success({
        title: "Some LLC",
        owner: {
          name: "John Smith",
          title: "CEO"
        }
      })

      #

      schema = described_class.schema do
        hash_schema(
          title: string,
          owner: {
            name: string,
            title: string & validate(inclusion: {in: %w(director CEO)})
          },
          details: hash_value
        )
      end

      params = {
        title: "Some LLC",
        owner: {
          name: "John Smith",
          title: "CEO"
        },
        details: {
          key: {
            value: 1
          }
        }
      }

      expect(schema.(params).to_dry_result).to eq Success({
        title: "Some LLC",
        owner: {
          name: "John Smith",
          title: "CEO"
        },
        details: {
          key: {
            value: 1
          }
        }
      })
    end

    it "processes array inside of hash" do
      schema = described_class.schema do
        hash_schema(
          title: string,
          external_ids: [to_integer]
        )
      end

      params = {
        title: "message",
        external_ids: [1, "2", 3]
      }

      expect(schema.(params).to_dry_result).to eq Success({
        title: "message",
        external_ids: [1, 2, 3]
      })

      params = {
        title: "message",
        external_ids: [1, "test", "not integer", 4]
      }

      expect(schema.(params).to_dry_result).to eq Failure({
        external_ids: {1 => ["must be integer"], 2 => ["must be integer"]}
      })
    end

    it "merges errors to 'base'" do
      schema = described_class.schema do
        length_is_4 = check("Length", "must contain exactly 4 elements") { |x| x.length == 4 }

        hash_schema(
          title: string,
          external_ids: length_is_4 * array_of(integer)
        )
      end

      params = {
        title: "message",
        external_ids: [1, "test", "not integer", 4, 5]
      }

      expect(schema.(params).to_dry_result).to eq Failure(
        external_ids: {base: ["must contain exactly 4 elements"], 1 => ["must be integer"], 2 => ["must be integer"]}
      )
    end

    context "processes hash inside of array" do
      it "checks for keys and removes unchecked keys" do
        schema = described_class.schema { array_schema(title: string) }

        params = [
          {title: "Person1"}, {title: "Person2", comment: "trader"}
        ]

        expect(schema.(params).to_dry_result).to eq Failure({
          1 => {comment: ["must be absent"]}
        })

        params = [
          {comment: "trader1"}, {title: "Person2"}
        ]

        # There is no way to provide 'comment: ["must be absent"]' error if
        # validation has failed mid way. Datacaster::Terminator::Raising can only
        # ensure that there are no excess fields if all previous validations
        # have passed.
        expect(schema.(params).to_dry_result).to eq Failure({
          0 => {title: ["must be string"]}
        })
      end

      it "allows multi-pass checks" do
        schema = described_class.schema do
          array_schema(title: string) & array_schema(name: string)
        end

        params = [{title: "Person 1", name: "John"}, {title: "Person 2", name: "James", occupation: "Trader"}]

        expect(schema.(params).to_dry_result).to eq Failure({
          1 => {occupation: ["must be absent"]}
        })

        #

        schema = described_class.schema do
          array_schema(title: string) & array_schema(occupation: string)
        end

        params = [{name: "John"}, {title: "Person 2", name: "James"}]

        expect(schema.(params).to_dry_result).to eq Failure({
          0 => {title: ["must be string"]}
        })

        #

        params = [{title: "Person 1", name: "James"}, {name: "John"}]

        expect(schema.(params).to_dry_result).to eq Failure({
          1 => {title: ["must be string"]}
        })

        #

        schema = described_class.schema do
          array_schema(title: string) * array_schema(occupation: string)
        end

        params = [{name: "James"}, {name: "John", title: "Person 2"}]

        expect(schema.(params).to_dry_result).to eq Failure({
          0 => {title: ["must be string"], occupation: ["must be string"]},
          1 => {occupation: ["must be string"]}
        })
      end

      it "yields separate error for array item with extra and absent fields" do
        schema = described_class.schema { array_schema(title: string) }

        expect(schema.([{title: "test"}]).to_dry_result).to eq Success([{title: "test"}])

        expect(schema.([{}]).to_dry_result).to eq Failure({0 => {title: ["must be string"]}})

        expect(schema.([{title: "test", extra: :field}, {title: "test2", extra2: :field}]).to_dry_result).to eq Failure({
          0 => {extra: ["must be absent"]},
          1 => {extra2: ["must be absent"]}
        })
      end
    end

    it "processes array inside of array" do
      schema = described_class.schema do
        two_elements = array_schema(integer) & validate(length: {is: 2})
        points = array_schema(two_elements)
      end

      params = [[0, 1], [2, 3], [4, 5]]

      expect(schema.(params).to_dry_result).to eq Success([[0, 1], [2, 3], [4, 5]])

      params = [[0, 1, 2], [2, "3"], [4, 5]]

      expect(schema.(params).to_dry_result).to eq Failure({
        0 => ["is the wrong length (should be 2 characters)"],
        1 => {1 => ["must be integer"]}
      })
    end
  end

  describe "constant mapping" do
    it "returns exact value" do
      t = Datacaster.schema { transform_to_value("Test") }

      expect(t.(123).to_dry_result).to eq Success("Test")
    end
  end

  describe "pick mapping" do
    before do
      @t = Datacaster.schema { pick(0) }
    end

    it "picks value from hash" do
      expect(@t.(0 => :a).to_dry_result).to eq Success(:a)
    end

    it "picks value from array" do
      expect(@t.([:a]).to_dry_result).to eq Success(:a)
    end

    it "returns Absent if there is not any value" do
      expect(@t.(1 => :b).to_dry_result).to eq Success(Datacaster.absent)
    end

    it "returns nil if the value is nil" do
      expect(@t.(0 => nil).to_dry_result).to eq Success(nil)
    end

    it "returns failure if object is not enumerable" do
      expect(@t.(1).to_dry_result).to eq Failure(["must be Enumerable"])
    end
  end

  describe "hash mapping" do
    subject { Datacaster.schema { transform_to_hash(a: pick(:b), b: transform_to_value(Datacaster.absent)) } }

    it "is able to pick fields from hash" do
      expect(subject.(b: 123).to_dry_result).to eq Success({a: 123})
    end

    it "works with fields equal to false" do
      expect(subject.(b: false).to_dry_result).to eq Success({a: false})
    end

    it "works with fields equal to nil" do
      expect(subject.(b: nil).to_dry_result).to eq Success({a: nil})
    end

    it "doesn't fail when picked fileds are missing" do
      expect(subject.({}).to_dry_result).to eq Success({})
    end

    it "Fails on extra fields" do
      expect(subject.({b: 5, c: 1}).to_dry_result).to eq Failure({c: ["must be absent"]})
      expect(subject.({c: 1}).to_dry_result).to eq Failure({c: ["must be absent"]})
    end

    it "could be sequenced with &" do
      mapping = Datacaster.schema do
        transform_to_hash(a: pick(:b), b: transform_to_value(Datacaster.absent)) &
        transform_to_hash(c: pick(:d), d: transform_to_value(Datacaster.absent))
      end

      expect(mapping.({b: 5, d: 3}).to_dry_result).to eq Success({a: 5, c: 3})
    end

    it "parses all fields independently" do
      mapping = Datacaster.schema { transform_to_hash(a: pick(:b), b: pick(:a)) }

      expect(mapping.({b: 5, a: 3}).to_dry_result).to eq Success({a: 5, b: 3})
    end

    it "allows to pick multiple fields" do
      mapping = Datacaster.schema do
        transform_to_hash(
          a: pick(:b, :c) & transform_if_present { |b, c| b + c },
          b: transform_to_value(Datacaster.absent),
          c: transform_to_value(Datacaster.absent)
        )
      end

      expect(mapping.(b: 3, c: 10).to_dry_result).to eq Success({a: 13})
    end

    it "allows to pick multiple fields and set their value to single" do
      mapping = Datacaster.schema do
        transform_to_hash(
          a1: pick(:b, :c),
          [:a2] => pick(:b) & transform { [_1] },
          b: remove,
          c: remove
        )
      end

      expect(mapping.(b: 3, c: 10).to_dry_result).to eq Success({
        a1: [3, 10],
        a2: 3
      })
    end

    it "allows to pick multiple fields and set their value to single" do
      mapping = Datacaster.schema do
        transform_to_hash(
          a1: pick(:b, :c),
          [:a2] => pick(:b) & transform { [_1] },
          b: remove,
          c: remove
        )
      end

      expect(mapping.(b: 3, c: 10).to_dry_result).to eq Success({
        a1: [3, 10],
        a2: 3
      })
    end

    it "doesn't allow to pick intersecting fields when picking multiple fields" do
      expect {
        Datacaster.schema do
          transform_to_hash(
            [:a, :b] => transform_to_value([1, 2]),
            :b => transform_to_value(5)
          )
        end
      }.to raise_error(ArgumentError)
    end

    it "allows to set multiple fields" do
      mapping = Datacaster.schema do
        transform_to_hash(
          [:a, :b, :c] => pick(:a, :b, :c) & transform_if_present { |a, b, c| [c, a, b] }
        )
      end

      expect(mapping.(a: 1, b: 2, c: 3).to_dry_result).to eq Success({a: 3, b: 1, c: 2})

      mapping = Datacaster.schema do
        transform_to_hash(
          [:a, :b] => pick(:a, :b) & cast { |a, b| a > b ? Success([b, a]) : Failure([["less than b"], []]) },
        )
      end
      expect(mapping.(a: 3, b: 2).to_dry_result).to eq Success({a: 2, b: 3})
      expect(mapping.(a: 1, b: 2).to_dry_result).to eq Failure({a: ["less than b"]})
    end

    describe "merge_message_keys" do
      it "merges keys" do
        mapping = Datacaster.schema do
          transform_to_hash(
            a: merge_message_keys(:b, :c),
            b: remove,
            c: remove
          )
        end

        expect(mapping.(b: 3, c: 10).to_dry_result).to eq Success({a: [3, 10]})
      end

      it "merges hashes" do
        mapping = Datacaster.schema do
          transform_to_hash(
            a: merge_message_keys(:b, :c),
            b: remove,
            c: remove
          )
        end

        expect(mapping.(b: {a: 'asd'}, c: {a: '321', b: '123'}).to_dry_result)
          .to eq Success({a: {a: ["asd", "321"], b: ["123"]}})
      end

      it "merges large hashes recusively" do
        mapping = Datacaster.schema do
          transform_to_hash(
            a: merge_message_keys(:b, :c),
            b: remove,
            c: remove
          )
        end

        expect(
          mapping.(
            b: {
              a: { a: "1" }
            },
            c: {
              a: { a: "2" }
            }
          ).to_dry_result
        ).to eq(
          Success(
            a: {
              a: {
                a: ["1", "2"]
              }
            }
          )
        )
      end

      it "warps scalar values into array" do
        mapping = Datacaster.schema do
          transform_to_hash(
            a: merge_message_keys(:a)
          )
        end

        expect(
          mapping.(a: "1").to_dry_result
        ).to eq(
          Success(a: ["1"])
        )
      end

      it "doesn't change incoming hash" do
        mapping = Datacaster.schema do
          transform_to_hash(
            a: merge_message_keys(:a),
            b: pick(:a)
          )
        end

        expect(
          mapping.(a: "1").to_dry_result
        ).to eq(
          Success(a: ["1"], b: "1")
        )
      end

      it "works correctly with multiple types of data" do
        mapping = Datacaster.schema do
          transform_to_hash(
            a: merge_message_keys(:a),
            b: merge_message_keys(:b, :c),
            c: remove
          )
        end

        expect(
          mapping.(
            a: "1", b: {c: "asd", d: "123"}, c: {e: "asd", d: "456"}
          ).to_dry_result
        ).to eq(
          Success(
            {a: ["1"], b: {c: ["asd"], d: ["123", "456"], e: ["asd"]}}
          )
        )
      end

      it "works correctly with false values" do
        mapping = Datacaster.schema do
          transform_to_hash(
            a: merge_message_keys(:a),
            b: merge_message_keys(:b, :c),
            c: remove
          )
        end

        expect(
          mapping.(
            a: false, b: {c: "asd", d: "123"}, c: {e: "asd", d: "456"}
          ).to_dry_result
        ).to eq(
          Success(
            {a: [false], b: {c: ["asd"], d: ["123", "456"], e: ["asd"]}}
          )
        )
      end

      it "ingore keys with nil and [] values" do
        mapping = Datacaster.schema do
          transform_to_hash(
            a: merge_message_keys(:a),
            b: merge_message_keys(:b, :c),
            c: remove,
            d: remove
          )
        end

        expect(
          mapping.(
            a: nil, b: {c: nil, d: "123"}, c: {e: "asd", d: "456", f: []}, d: []
          ).to_dry_result
        ).to eq(
          Success(
            {b: {d: ["123", "456"], e: ["asd"]}}
          )
        )
      end

      it "works with simple hash input" do
        mapper = Datacaster.schema do
          merge_message_keys(:a, :b)
        end

        expect(
          mapper.(a: "1", b: "2").to_dry_result
        ).to eq(
          Success(["1", "2"])
        )
      end

      it "merges non Hash objects to :base key" do
        mapping = Datacaster.schema do
          transform_to_hash(
            a: merge_message_keys(:a),
            b: merge_message_keys(:b, :c, :d),
            c: remove,
            d: remove
          )
        end

        expect(
          mapping.(
            a: "1", b: {c: "asd", d: "123"}, c: "test", d: 123
          ).to_dry_result
        ).to eq(
          Success(
            {a: ["1"], b: {base: ["test", 123], d: ["123"], c: ["asd"]}}
          )
        )
      end
    end

    describe "choosy schema" do
      it "removes unused keys with transform_to_hash" do
        params = {
          name: "test",
          email: "test@email"
        }

        subject = Datacaster.choosy_schema do
          transform_to_hash(
            name: pick(:name)
          )
        end

        expect(subject.(params).to_dry_result).to eq Success({name: "test"})
      end

      it "is able to pick multiple keys for a new hash" do
        params = {
          name: "test",
          email: "test@email"
        }

        subject = Datacaster.choosy_schema do
          transform_to_hash(
            user_info: pick(:name, :email) & transform { |a, b| "#{a}:#{b}" }
          )
        end

        expect(subject.(params).to_dry_result).to eq Success({user_info: "test:test@email"})
      end

      it "removes unmentioned keys with hash_schema" do
        params = {
          name: "test",
          email: "test@email",
          phone: "123456789"
        }

        subject = Datacaster.choosy_schema do
          hash_schema(
            name: string,
            email: string,
          )
        end

        expect(subject.(params).to_dry_result)
          .to eq Success({name: "test", email: "test@email"})
      end
    end
  end
end
