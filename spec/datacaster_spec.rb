RSpec.describe Datacaster do
  include Dry::Monads[:result]

  describe "absent typecasting" do
    subject { described_class.schema { absent } }

    it "returns Success on Datacaster.absent" do
      expect(subject.(Datacaster.absent).to_dry_result).to eq Success(Datacaster.absent)
    end

    it "returns Failure on some value" do
      expect(subject.(5).to_dry_result).to eq Failure(["should be absent"])
    end

    it "returns Failure on nil" do
      expect(subject.(nil).to_dry_result).to eq Failure(["should be absent"])
    end

    it "returns Success on nils with on: :nil?" do
      schema = described_class.schema { absent(on: :nil?) }
      expect(schema.(nil).to_dry_result).to eq Success(Datacaster.absent)
      expect(schema.(Datacaster.absent).to_dry_result).to eq Success(Datacaster.absent)
    end
  end

  describe "any typecasting" do
    subject { described_class.schema { any } }

    it "passes anything" do
      expect(subject.("test").to_dry_result).to eq Success("test")
      expect(subject.(nil).to_dry_result).to eq Success(nil)
    end

    it "returns Failure on Absent" do
      expect(subject.(Datacaster.absent).to_dry_result).to eq Failure(["should be present"])
    end
  end

  describe "compare typecasting" do
    subject { described_class.schema { compare(5) } }

    it "passes exact value and fails on everything else" do
      expect(subject.(5).to_dry_result).to eq Success(5)
      expect(subject.(nil).to_dry_result).to eq Failure(["does not equal 5"])
      expect(subject.(Datacaster.absent).to_dry_result).to eq Failure(["does not equal 5"])
      expect(subject.(6).to_dry_result).to eq Failure(["does not equal 5"])
    end
  end

  describe "default typecasting" do
    subject { described_class.schema { default(5) } }

    it "passes anything" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "transforms to default on absent" do
      expect(subject.(Datacaster.absent).to_dry_result).to eq Success(5)
    end

    it "doesn't transform to default on nils" do
      expect(subject.(nil).to_dry_result).to eq Success(nil)
    end

    it "transforms to default when :on points to method which returns truthfully" do
      schema = described_class.schema { default(5, on: :nil?) }
      expect(schema.(nil).to_dry_result).to eq Success(5)
      expect(schema.(1).to_dry_result).to eq Success(1)
      expect(schema.(Datacaster.absent).to_dry_result).to eq Success(5)
    end

    it "doesn't transform when value doesn't respond to method set in :on" do
      schema = described_class.schema { default(5, on: :blabla) }
      expect(schema.(nil).to_dry_result).to eq Success(nil)
      expect(schema.(1).to_dry_result).to eq Success(1)
      expect(schema.(Datacaster.absent).to_dry_result).to eq Success(5)
    end

    it "returns deeply frozen default value" do
      schema = described_class.schema { default([{}], on: :nil?) }
      expect { schema.(nil).value!.first[:a] = "b" }.to raise_error FrozenError
    end
  end

  describe "included_in typecasting" do
    subject { described_class.schema { included_in([1, '2', ['test']]) } }

    it "passes one of the exact values and fails on everything else" do
      expect(subject.(1).to_dry_result).to eq Success(1)
      expect(subject.('2').to_dry_result).to eq Success('2')
      expect(subject.(['test']).to_dry_result).to eq Success(['test'])

      expect(subject.(2).to_dry_result).to eq Failure(['is not one of 1, 2, ["test"]'])
      expect(subject.([]).to_dry_result).to eq Failure(['is not one of 1, 2, ["test"]'])
      expect(subject.(nil).to_dry_result).to eq Failure(['is not one of 1, 2, ["test"]'])
    end
  end

  describe "string typecasting" do
    subject { described_class.schema { string } }

    it "passes strings" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "returns Failure on integeres" do
      expect(subject.(1).to_dry_result).to eq Failure(["is not a string"])
    end

    it "returns Failure on nils" do
      expect(subject.(nil).to_dry_result).to eq Failure(["is not a string"])
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
      expect(subject.(1).to_dry_result).to eq Failure(["is not a string"])
    end

    it "returns Failure on empty strings" do
      expect(subject.("").to_dry_result).to eq Failure(["should be non-empty string"])
    end
  end

  describe "non-empty array typecasting" do
    subject { described_class.schema { non_empty_array } }

    it "passes strings" do
      expect(subject.(["test"]).to_dry_result).to eq Success(["test"])
    end

    it "returns Failure on integeres" do
      expect(subject.(1).to_dry_result).to eq Failure(["should be an array"])
    end

    it "returns Failure on empty arrays" do
      expect(subject.([]).to_dry_result).to eq Failure(["should not be empty"])
    end
  end

  describe "UUID string typecasting" do
    subject { described_class.schema { uuid } }

    it "passes UUID strings" do
      uuid = "58724b11-ff06-485e-bf67-410c96f606d7"

      expect(subject.(uuid).to_dry_result).to eq Success(uuid)
    end

    it "returns Failure on integers" do
      expect(subject.(1).to_dry_result).to eq Failure(["is not UUID"])
    end

    it "returns Failure on non-UUID strings" do
      uuid_without_last_symbol = "58724b11-ff06-485e-bf67-410c96f606d"

      expect(subject.(uuid_without_last_symbol).to_dry_result).to eq Failure(["is not UUID"])
    end
  end

  describe "numeric typecasting" do
    subject { described_class.schema { numeric } }

    it "passes integers" do
      expect(subject.(2_147_483_647).to_dry_result).to eq Success(2_147_483_647)
    end

    it "passes floats" do
      expect(subject.(1.33).to_dry_result).to eq Success(1.33)
    end

    it "passes decimals" do
      expect(subject.(1.33.to_d).to_dry_result).to eq Success(1.33.to_d)
    end

    it "passes rationals" do
      expect(subject.(2/3r).to_dry_result).to eq Success(2/3r)
    end

    it "passes complex numbers" do
      expect(subject.(3i).to_dry_result).to eq Success(3i)
    end

    it "returns Failure on string numbers" do
      expect(subject.("100").to_dry_result).to eq Failure(["is not a number"])
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
      expect(subject.(nil).to_dry_result).to eq Failure(["is not a decimal number"])
    end
  end

  describe "integer32 typecasting" do
    subject { described_class.schema { integer32 } }

    it "passes 32-bit integers" do
      expect(subject.(2_147_483_647).to_dry_result).to eq Success(2_147_483_647)
    end

    it "returns Failure on non-integers" do
      expect(subject.("100").to_dry_result).to eq Failure(["is not an integer"])
    end

    it "returns Failure on too big integers" do
      expect(subject.(2_147_483_648).to_dry_result).to eq Failure(["is not a 32-bit integer"])
    end
  end

  describe "maximum typecasting" do
    context "when inclusive implicitly" do
      subject { described_class.schema { maximum(4, inclusive: true) } }

      it "passes less than maximum" do
        expect(subject.(3).to_dry_result).to eq Success(3)
      end

      it "passes equal to maximum" do
        expect(subject.(4).to_dry_result).to eq Success(4)
      end

      it "doesn't pass greater than maximum" do
        expect(subject.(5).to_dry_result).to eq Failure(["should be less than or equal to 4"])
      end

      it "doesn't pass non-numerics" do
        expect(subject.(:'123').to_dry_result).to eq Failure(["is not a number"])
      end
    end

    context "when inclusive explicitly" do
      subject { described_class.schema { maximum(4) } }

      it "passes less than maximum" do
        expect(subject.(3).to_dry_result).to eq Success(3)
      end

      it "passes equal to maximum" do
        expect(subject.(4).to_dry_result).to eq Success(4)
      end

      it "doesn't pass greater than maximum" do
        expect(subject.(5).to_dry_result).to eq Failure(["should be less than or equal to 4"])
      end

      it "doesn't pass non-numerics" do
        expect(subject.(:'123').to_dry_result).to eq Failure(["is not a number"])
      end
    end

    context "when exclusive" do
      subject { described_class.schema { maximum(4, inclusive: false) } }

      it "passes less than maximum" do
        expect(subject.(3).to_dry_result).to eq Success(3)
      end

      it "doesn't pass equal to maximum" do
        expect(subject.(4).to_dry_result).to eq Failure(["should be less than 4"])
      end

      it "doesn't pass greater than maximum" do
        expect(subject.(5).to_dry_result).to eq Failure(["should be less than 4"])
      end

      it "doesn't pass non-numerics" do
        expect(subject.(:'123').to_dry_result).to eq Failure(["is not a number"])
      end
    end
  end

  describe "minimum typecasting" do
    context "when inclusive implicitly" do
      subject { described_class.schema { minimum(4, inclusive: true) } }

      it "passes greater than minimum" do
        expect(subject.(5).to_dry_result).to eq Success(5)
      end

      it "passes equal to minimum" do
        expect(subject.(4).to_dry_result).to eq Success(4)
      end

      it "doesn't pass less than minimum" do
        expect(subject.(3).to_dry_result).to eq Failure(["should be greater than or equal to 4"])
      end

      it "doesn't pass non-numerics" do
        expect(subject.(:'123').to_dry_result).to eq Failure(["is not a number"])
      end
    end

    context "when inclusive explicitly" do
      subject { described_class.schema { minimum(4) } }

      it "passes greater than minimum" do
        expect(subject.(5).to_dry_result).to eq Success(5)
      end

      it "passes equal to minimum" do
        expect(subject.(4).to_dry_result).to eq Success(4)
      end

      it "doesn't pass less than minimum" do
        expect(subject.(3).to_dry_result).to eq Failure(["should be greater than or equal to 4"])
      end

      it "doesn't pass non-numerics" do
        expect(subject.(:'123').to_dry_result).to eq Failure(["is not a number"])
      end
    end

    context "when exclusive" do
      subject { described_class.schema { minimum(4, inclusive: false) } }

      it "passes greater than minimum" do
        expect(subject.(5).to_dry_result).to eq Success(5)
      end

      it "doesn't pass equal to minimum" do
        expect(subject.(4).to_dry_result).to eq Failure(["should be greater than 4"])
      end

      it "doesn't pass less than minimum" do
        expect(subject.(3).to_dry_result).to eq Failure(["should be greater than 4"])
      end

      it "doesn't pass non-numerics" do
        expect(subject.(:'123').to_dry_result).to eq Failure(["is not a number"])
      end
    end
  end

  describe "pattern typecasting" do
    subject { described_class.schema { pattern(/\A\d+\z/) } }

    it "passes correctly formatted strings" do
      expect(subject.("123").to_dry_result).to eq Success("123")
      expect(subject.("ab123").to_dry_result).to eq Failure(["has invalid format"])
    end

    it "doesn't pass non-strings" do
      expect(subject.(:'123').to_dry_result).to eq Failure(["is not a string"])
    end
  end

  describe "optional string typecasting" do
    subject { described_class.schema { optional(string) } }

    it "passes strings" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "returns Failure on integeres" do
      expect(subject.(1).to_dry_result).to eq Failure(["is not a string"])
    end

    it "returns Failure on nils" do
      expect(subject.(nil).to_dry_result).to eq Failure(["is not a string"])
    end

    it "returns Success on nils with on: :nil?" do
      schema = described_class.schema { optional(string, on: :nil?) }
      expect(schema.(nil).to_dry_result).to eq Success(Datacaster.absent)
      expect(schema.(Datacaster.absent).to_dry_result).to eq Success(Datacaster.absent)
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

  describe "relate typecasting" do
    it "performs picks and transforms with shotrcut definition" do
      schema = Datacaster.schema { relate(:a, :<, :b) }

      expect(schema.(a: 1, b: 2).to_dry_result).to eq Success(a: 1, b: 2)
      expect(schema.(a: 2, b: 1).to_dry_result).to eq Failure(["a should be < b"])
    end

    it "performs picks and transforms with nested shotrcut definition" do
      schema = Datacaster.schema { relate([:a, :b], :<, [:c, :d]) }

      expect(schema.(a: { b: 1 }, c: { d: 2 }).to_dry_result).to eq Success(a: { b: 1 }, c: { d: 2 })
      expect(schema.(a: { b: 2 }, c: { d: 1 }).to_dry_result).to eq Failure(["2 should be < 1"])
    end

    it "performs picks and transforms with full definition" do
      schema = Datacaster.schema { relate(transform(&:length), :==, transform_to_value(5)) }

      expect(schema.([1, 2, 3, 4, 5]).to_dry_result).to eq Success([1, 2, 3, 4, 5])
      expect(schema.([1, 2, 3, 4]).to_dry_result).to eq Failure(["4 should be == 5"])
    end

    it "passes first pick result on error" do
      schema = Datacaster.schema { relate(check('datacaster.errors.integer') { false }, :<, check { false }) }

      expect(schema.(b: 1).to_dry_result).to eq Failure(["is not an integer"])
    end

    it "passes second pick result on error if first is valid" do
      schema = Datacaster.schema { relate(pass, :<, check('datacaster.errors.integer') { false }) }

      expect(schema.(b: 1).to_dry_result).to eq Failure(["is not an integer"])
    end
  end

  describe "string optional param typecasting" do
    subject { described_class.schema { optional_param(string) } }

    it "passes strings" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "returns failure with integers" do
      expect(subject.(1).to_dry_result).to eq Failure(["is not a string"])
    end

    it "returns failure with nils" do
      expect(subject.(nil).to_dry_result).to eq Failure(["is not a string"])
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
      expect(schema.(title: nil).to_dry_result).to eq Failure({title: ["is not a string"]})
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
      expect(subject.(nil).to_dry_result).to eq Failure(["does not look like an integer"])
    end

    it "returns Failure on empty string" do
      expect(subject.("").to_dry_result).to eq Failure(["does not look like an integer"])
    end

    it "returns Failure when unable to coerce" do
      expect(subject.("no number").to_dry_result).to eq Failure(["does not look like an integer"])
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
      expect(subject.(nil).to_dry_result).to eq Failure(["does not look like a float"])
    end

    it "returns Failure on empty string" do
      expect(subject.("").to_dry_result).to eq Failure(["does not look like a float"])
    end

    it "returns Failure when unable to coerce" do
      expect(subject.("no number").to_dry_result).to eq Failure(["does not look like a float"])
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
      expect(subject.(nil).to_dry_result).to eq Failure(["does not look like a boolean"])
    end

    it "returns Failure when unable to coerce" do
      expect(subject.("not a boolean").to_dry_result).to eq Failure(["does not look like a boolean"])
    end
  end

  describe "iso8601 typecasting" do
    subject { described_class.schema { iso8601 } }

    it "treats strings as iso8601 date-time" do
      expect(subject.("2019-03-01T12:30:20Z").to_dry_result).to eq Success(DateTime.parse("2019-03-01T12:30:20Z"))
    end

    it "returns Failure when unable to coerce" do
      expect(subject.("2019-03-01T12:70:20Z").to_dry_result).to eq Failure(["is not a string with ISO-8601 date and time"])
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

      expect(type.(nil).to_dry_result).to eq Failure(["is not a hash"])
    end

    it "fails on empty strings" do
      type = described_class.schema { hash_schema(a: to_integer, b: to_float) }

      expect(type.("").to_dry_result).to eq Failure(["is not a hash"])
    end

    it "returns failure if additional fields present" do
      type = described_class.schema { hash_schema(a: to_integer, b: to_float) }

      expect(type.({a: "1", b: "2.35", c: "other", d: 1234}).to_dry_result).to eq \
        Failure({c: ["must be absent"], d: ["must be absent"]})
    end

    it "aggregates Failures among fields" do
      type = described_class.schema { hash_schema(a: to_integer, b: to_boolean) }

      expect(type.({a: "not a number", b: "not a boolean"}).to_dry_result).to eq \
        Failure(a: ["does not look like an integer"], b: ["does not look like a boolean"])
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

      expect(subject.(params).to_dry_result).to eq Failure(user_info: ["should be present"])
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
      expect(subject.(:not_even_string).to_dry_result).to eq Failure(["is not a string"])
    end

    it "returns right Failure, when left is Success and right is Failure" do
      expect(subject.("not_test").to_dry_result).to eq Failure(['does not equal "test"'])
    end
  end

  describe "and node with .steps(...)" do
    subject do
      described_class.schema do
        steps(
          string,
          check { |x| x.length <= 5 },
          compare("test")
        )
      end
    end

    it "returns Success when all are valid" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    it "returns first ErrorResult, when first is ErrorResult" do
      expect(subject.(:not_even_string).to_dry_result).to eq Failure(["is not a string"])
    end

    it "returns second ErrorResult, when second is ErrorResult" do
      expect(subject.("too long").to_dry_result).to eq Failure(["is invalid"])
    end

    it "returns the last ErrorResult, when the last is ErrorResult" do
      expect(subject.("tset").to_dry_result).to eq Failure(['does not equal "test"'])
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
      expect(subject.(:a_symbol).to_dry_result).to eq Failure(["is not an integer"])
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
      expect(subject.({a: :not_string, b: 5}).to_dry_result).to eq Failure({a: ["is not a string"]})
    end

    it "returns right Failure when only right is Failure" do
      expect(subject.({a: "test", b: :not_integer}).to_dry_result).to eq Failure({b: ["is not an integer"]})
    end

    it "returns aggregated failures when both are Failure" do
      expect(subject.({a: :not_string, b: :not_integer}).to_dry_result).to eq \
        Failure({a: ["is not a string"], b: ["is not an integer"]})
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
      expect(subject.(:not_string).to_dry_result).to eq Failure(["is not an integer"])
    end

    it "returns 'then' Success, if left is Success and 'then' is Success" do
      expect(subject.("test").to_dry_result).to eq Success("test")
    end

    # N.B.: "a & b | c" would return "c" here, instead of "b's Failure"
    # That's the reason we need then-else as separate node
    it "returns 'then' Failure, if left is Success and 'then' is Failure" do
      expect(subject.("5").to_dry_result).to eq Failure(['does not equal "test"'])
    end

    it "supports constructing different 'then'-'else' nodes with the same 'then'" do
      schema = described_class.schema do
        half = string.then(compare("test"))
        a = half.else(transform_to_value(1))
        b = half.else(transform_to_value(2))
        hash_schema(a: a, b: b)
      end

      expect(schema.(a: 1, b: 1).to_dry_result).to eq Success({a: 1, b: 2})
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

  describe "hash schema composition" do
    subject do
      type_field_partial =
        described_class.partial_schema do
          hash_schema(
            type: string & transform_if_present(&:downcase) & check { |x| %(person entity).include?(x) }
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

      expect(subject.(params).to_dry_result).to eq Failure(type: ["is invalid"])

      params = {
        type: "Person",
        name: nil,
        dob: "1980-01-01",
        details: "123",
        comment: nil
      }

      expect(subject.(params).to_dry_result).to eq Failure(name: ["is not a string"], comment: ["is not a string"])
    end
  end

  describe "hash schema DSL" do
    subject do
      Datacaster.schema do
        type_validation = hash_schema(
          type: string & transform_if_present(&:downcase) & check { |x| %(person entity).include?(x) }
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

      expect(subject.(params).to_dry_result).to eq Failure(name: ["is not a string"], comment: ["is not a string"])
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
        1 => ["is not an integer"],
        3 => ["is not an integer"]
      )
    end

    it "succeeds on empty array" do
      expect(subject.([]).to_dry_result).to eq Success([])
    end

    context 'when schema disallows empty' do
      subject { described_class.schema { array_schema(integer, allow_empty: false) } }

      it "allows empty array" do
        expect(subject.([]).to_dry_result).to eq Failure(["should not be empty"])
      end
    end
  end

  describe "recursive schemas" do
    it "process hash inside of hash" do
      schema = described_class.schema do
        hash_schema(
          title: string,
          owner: {
            name: string,
            title: string & check { |x| %(director CEO).include?(x) }
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
        title: ["is not a string"],
        owner: {
          title: ["is invalid"]
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
            title: string & check { |x| %(director CEO).include?(x) }
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
        external_ids: {1 => ["does not look like an integer"], 2 => ["does not look like an integer"]}
      })
    end

    it "merges errors to 'base'" do
      schema = described_class.schema do
        length_is_4 = check { |x| x.length == 4 }.cast_errors(transform_to_value('must contain exactly 4 elements'))

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
        external_ids: {base: ["must contain exactly 4 elements"], 1 => ["is not an integer"], 2 => ["is not an integer"]}
      )
    end

    context "processes hash inside of array" do
      it "checks for keys and removes unchecked keys" do
        schema = described_class.schema { array_schema({title: string}) }

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
          0 => {title: ["is not a string"]}
        })
      end

      it "allows multi-pass checks" do
        schema = described_class.schema do
          array_schema({title: string}) & array_schema({name: string})
        end

        params = [{title: "Person 1", name: "John"}, {title: "Person 2", name: "James", occupation: "Trader"}]

        expect(schema.(params).to_dry_result).to eq Failure({
          1 => {occupation: ["must be absent"]}
        })

        #

        schema = described_class.schema do
          array_schema({title: string}) & array_schema({occupation: string})
        end

        params = [{name: "John"}, {title: "Person 2", name: "James"}]

        expect(schema.(params).to_dry_result).to eq Failure({
          0 => {title: ["is not a string"]}
        })

        #

        params = [{title: "Person 1", name: "James"}, {name: "John"}]

        expect(schema.(params).to_dry_result).to eq Failure({
          1 => {title: ["is not a string"]}
        })

        #

        schema = described_class.schema do
          array_schema({title: string}) * array_schema({occupation: string})
        end

        params = [{name: "James"}, {name: "John", title: "Person 2"}]

        expect(schema.(params).to_dry_result).to eq Failure({
          0 => {title: ["is not a string"], occupation: ["is not a string"]},
          1 => {occupation: ["is not a string"]}
        })
      end

      it "yields separate error for array item with extra and absent fields" do
        schema = described_class.schema { array_schema({title: string}) }

        expect(schema.([{title: "test"}]).to_dry_result).to eq Success([{title: "test"}])

        expect(schema.([{}]).to_dry_result).to eq Failure({0 => {title: ["is not a string"]}})

        expect(schema.([{title: "test", extra: :field}, {title: "test2", extra2: :field}]).to_dry_result).to eq Failure({
          0 => {extra: ["must be absent"]},
          1 => {extra2: ["must be absent"]}
        })
      end
    end

    it "processes array inside of array" do
      schema = described_class.schema do
        two_elements = array_schema(integer) & check { |x| x.length == 2 }.cast_errors(transform_to_value('is the wrong length (should be 2 characters)'))
        points = array_schema(two_elements)
      end

      params = [[0, 1], [2, 3], [4, 5]]

      expect(schema.(params).to_dry_result).to eq Success([[0, 1], [2, 3], [4, 5]])

      params = [[0, 1, 2], [2, "3"], [4, 5]]

      expect(schema.(params).to_dry_result).to eq Failure({
        0 => ["is the wrong length (should be 2 characters)"],
        1 => {1 => ["is not an integer"]}
      })
    end
  end

  describe "constant mapping" do
    let(:transform_to_value_caster) do
      Datacaster.schema { transform_to_value({ a: { b: { c: ["d"] } } }) }
    end

    let(:returned_value) do
      transform_to_value_caster.(123).value!
    end

    it "returns exact value" do
      expect(returned_value).to eq({ a: { b: { c: ["d"] } } })
    end

    it "freezes returned value" do
      expect(returned_value).to be_frozen
    end

    it "freezes deeply" do
      expect { returned_value[:a][:b][:c].pop }.to raise_error FrozenError
    end
  end

  describe "pass_if casting" do
    subject { Datacaster.schema { pass_if(check { |x| x[:test] == 0 }) } }

    it "passes original if cast succeeds" do
      expect(subject.(test: 0).to_dry_result).to eq Success(test: 0)
    end

    it "passes error" do
      expect(subject.(test: 1).to_dry_result).to eq Failure(['is invalid'])
    end
  end

  describe "pick mapping" do
    context "when non array keys are used" do
      subject { Datacaster.schema { pick(0) } }

      it "picks value from hash" do
        expect(subject.(0 => :a).to_dry_result).to eq Success(:a)
      end

      it "picks value from array" do
        expect(subject.([:a]).to_dry_result).to eq Success(:a)
      end

      it "returns Absent if there is not any value" do
        expect(subject.(1 => :b).to_dry_result).to eq Success(Datacaster.absent)
      end

      it "returns nil if the value is nil" do
        expect(subject.(0 => nil).to_dry_result).to eq Success(nil)
      end

      it "returns failure if object is not enumerable" do
        expect(subject.(1).to_dry_result).to eq Failure(["is not Enumerable"])
      end
    end

    context "when array keys are used" do
      subject { Datacaster.schema { pick([:offer, :amount]) } }

      it "returns values from nested hash" do
        expect(subject.(offer: {amount: 5}).to_dry_result).to eq Success(5)
      end
    end
  end

  describe "'with' typecasting" do
    it "picks and puts back single key" do
      schema = Datacaster.schema { with(:name, transform { |x| "#{x}-1" }) }
      expect(schema.(name: 'Josh').to_dry_result).to eq Success(name: 'Josh-1')
    end

    it "puts ErrorResult under the same key" do
      schema = Datacaster.schema { with(:name, integer) }
      expect(schema.(name: 'Josh').to_dry_result).to eq Failure(name: ["is not an integer"])
    end

    it "picks and puts back deeply nested key" do
      schema =
        Datacaster.schema do
          with([:person, :name], transform(&:upcase))
        end

      expect(schema.(person: {name: 'Josh'}).to_dry_result).to eq Success(person: {name: 'JOSH'})
    end

    it "returns absent when failed to pick" do
      schema =
        Datacaster.schema do
          with([:person, :name, :first], any)
        end

        expect(schema.(person: {}).to_dry_result).to eq Failure(person: {name: ["is not Enumerable"]})
    end
  end

  describe "attribute mapping" do
    context "when non array keys are used" do
      subject { Datacaster.schema { attribute(:test) } }

      let(:mock_object) do
        Class.new do
          def test
            "test"
          end
        end
      end

      it "takes attribute from object" do
        expect(subject.(mock_object.new).to_dry_result).to eq Success("test")
      end

      it "returns Datacaster.absent if method is not available" do
        expect(subject.(Class.new.new).to_dry_result).to eq Success(Datacaster.absent)
      end
    end

    context "when array keys are used" do
      subject { Datacaster.schema { pick([:offer, :amount]) } }

      let (:mock_object) do
        Class.new do
          def offer
            Class.new do
              def amount
                5
              end
            end.new
          end
        end
      end

      it "returns values from nested hash" do
        expect(subject.(offer: {amount: 5}).to_dry_result).to eq Success(5)
      end
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

  describe "using datacaster schema shotrcut" do
    it "works with schema" do
      subject = described_class.partial_schema do
        schema(
          hash_schema(
            name: string
          )
        )
      end

      expect(subject.(name: "test", surname: "asd").to_dry_result).to eq Failure(surname: ["must be absent"])
    end

    it "works with partial_schema" do
      subject = described_class.partial_schema do
        partial_schema(
          hash_schema(
            name: string
          )
        )
      end

      expect(subject.(name: "test", surname: "asd").to_dry_result).to eq Success(name: "test", surname: "asd")
    end

    it "works with choosy_schema" do
      subject = described_class.partial_schema do
        choosy_schema(
          hash_schema(
            name: string
          )
        )
      end

      expect(subject.(name: "test", surname: "asd").to_dry_result).to eq Success(name: "test")
    end
  end

  describe "adding custom casters" do
    it "adds custom caster via lambda definition" do
      Datacaster::Config.add_predefined_caster(:time_string, -> {
        string & check { |x| x =~ /\A(0[0-9]|1[0-9]|2[0-3]):[03]0\z/ }
      })

      schema = Datacaster.schema { time_string }

      expect(schema.("23:00").to_dry_result).to eq Success("23:00")
      expect(schema.("no_time_string").to_dry_result).to eq Failure(["is invalid"])
    end

    it "adds custom caster via datacaster instance" do
      CSS_COLOR = Datacaster.schema { string & check { |x| x =~ /\A#(?:\h{3}){1,2}\z/ } }
      Datacaster::Config.add_predefined_caster(:css_color, CSS_COLOR)

      schema = Datacaster.schema { css_color }

      expect(schema.("#123456").to_dry_result).to eq Success("#123456")
      expect(schema.("no_css_color").to_dry_result).to eq Failure(["is invalid"])
    end

    it "works with parameter in caster" do
      Datacaster::Config.add_predefined_caster(:super_compare, -> (param) {
        compare("super_#{param}")
      })

      schema = Datacaster.schema { super_compare(:test) }

      expect(schema.("super_test").to_dry_result).to eq Success("super_test")
      expect(schema.("no_super_test").to_dry_result).to eq Failure(["does not equal \"super_test\""])
    end
  end

  describe "cleaning nested schemas" do
    it "doesn't complain on keys checked in nested contex node" do
      schema = Datacaster.schema do
        schema(
          hash_schema(a: integer, b: integer)
        ) & hash_schema(b: integer)
      end

      expect(schema.(a: 1, b: 2).to_dry_result).to eq Success(a: 1, b: 2)
    end

    it "doesn't complain on nested keys in nested context node" do
      caster = Datacaster.schema do
        nested = schema(
          hash_schema(a: integer, b: integer)
        )

        hash_schema(nested: nested)
      end

      expect(caster.(nested: {a: 1, b: 2}).to_dry_result).to eq Success(nested: {a: 1, b: 2})
    end

    it "doesn't complain on keys in deeply nested strict schemas" do
      schema = Datacaster.schema do
        hash_schema(
          test: schema(hash_schema(a: integer, b: integer))
        )
      end

      expect(schema.(test: {a: 1, b: 2}).to_dry_result).to eq Success(test: {a: 1, b: 2})
    end
  end
end
