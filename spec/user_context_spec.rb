RSpec.describe Datacaster do
  include Dry::Monads[:result]

  describe "using context node (#with_context)" do
    it "allows to access context.something in runtime" do
      type = described_class.schema { check { |x| x == context.test } }

      expect(type.with_context(test: "asd").("asd").to_dry_result).to eq Success("asd")
    end

    it "allows to access context.something in deeply nested" do
      schema = described_class.schema do
        hash_schema(
          title: string,
          owner: {
            name: string,
            title: string & check { |v| v == context.params }
          }
        )
      end

      expect(
        schema.with_context(params: "CEO").(
          title: "title",
          owner: {
            name: "boss",
            title: "CEO"
          }
        ).to_dry_result
      ).to eq Success(
        title: "title",
        owner: {
          name: "boss",
          title: "CEO"
        }
      )
    end

    it "allows nesting and composition" do
      schema = described_class.schema do
        (check { |x| context.v * context.a * x == context.av }.with_context(v: 2) &
          check { |x| (context.v * 2) * x == context.av }.with_context(v: 3)).
          with_context(a: 3)
      end

      expect(schema.with_context(av: 6).(1).to_dry_result).to eq Success(1)
    end

    it "works with deep nesting" do
      schema = described_class.schema do
        check { |x| x == context.a }.
          with_context(b: 1).
          with_context(c: 2).
          with_context(d: 3)
      end

      expect(schema.with_context(a: 1).(1).to_dry_result).to eq Success(1)
    end

    it "works with complex schemas" do
      schema = described_class.schema do
        hash_schema(
          a: check { |v| v == context.a},
          b: {c: {d: check { |v| v == context.d}}},
          e: [check { |v| v == context.e }]
        ).with_context(a: 1)
      end

      expect(schema.with_context(d: 2, e: 3).({a: 1, b: {c: {d: 10}}, e: [3]}).to_dry_result).to eq Failure({b: {c: {d: ["is invalid"]}}})
    end
  end
end
