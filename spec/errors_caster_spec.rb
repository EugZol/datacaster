RSpec.describe Datacaster do
  include Dry::Monads[:result]

  describe "cast_errors" do
    context "remaps errors with #cast_errors" do
      it "with transform_to_hash" do
        type = described_class.schema do
          transform = transform_to_hash(
            b: pick(:a) & integer,
            a: remove
          )

          transform.cast_errors(
            transform_to_hash(
              a: pick(:b),
              b: remove
            )
          )
        end

        expect(type.(a: 'wrong').to_dry_result).to eq Failure(a: ["is not an integer"])
      end

      it "with pick" do
        type = described_class.schema do
          transform = transform_to_hash(
            b: pick(:a) & integer,
            a: remove
          )

          transform.cast_errors pick(:b)
        end

        expect(type.(a: 'wrong').to_dry_result).to eq Failure(["is not an integer"])
      end
    end

    it "remaps errors for complex schemas with composition" do
      schema1 = described_class.partial_schema do
        transform = transform_to_hash(
          b: pick(:a) & integer,
          a: remove
        )

        transform.cast_errors pick(:b)
      end

      schema2 = described_class.choosy_schema do
        transform = transform_to_hash(
          d: pick(:c) & integer,
          c: remove
        )
      end

      schema3 = described_class.schema do
        (schema1 * schema2).cast_errors(
          Datacaster.choosy_schema do
            transform_to_hash(
              c: pick(:d),
              base: pick(:base)
            )
          end
        )
      end

      expect(schema3.(a: "asd", c: "asd", e: "asd").to_dry_result)
        .to eq Failure(base: ["is not an integer"], c: ["is not an integer"])
    end

    it "raises an error in case of ErrorResult" do
      schema = Datacaster.schema do
        caster = to_integer

        caster.cast_errors to_integer
      end

      expect { schema.("not_an_int") }.to raise_error(RuntimeError)
    end
  end
end
