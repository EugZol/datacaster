require 'ostruct'

RSpec.describe Datacaster do
  include Dry::Monads[:result]

  describe "using context node (#with_object_context)" do
    it "allows access to instance variables" do
      object = Object.new
      object.instance_variable_set(:@a, 5)

      schema = Datacaster.schema do
        check { @a == 5 } & transform { |v| @a + v }
      end

      expect(schema.with_object_context(object).(1).to_dry_result).to eq Success(6)
    end

    it "allows modification of instance variables" do
      object = Object.new
      object.instance_variable_set(:@a, 5)

      schema = Datacaster.schema do
        check { @a = 6; @a == 6 } & transform { |v| @a + v }
      end

      expect(schema.with_object_context(object).(1).to_dry_result).to eq Success(7)
      expect(object.instance_variable_get(:@a)).to eq 6
    end

    it "allows method calls" do
      object = Object.new
      object.instance_variable_set(:@a, 5)
      object.singleton_class.define_method(:b) { @a * 100 }

      schema = Datacaster.schema do
        (check { b == 500 } & transform { |v| @a = 6; @a + v }).
          with_object_context(object)
      end

      expect(schema.with_object_context(object).(1).to_dry_result).to eq Success(7)
      expect(object.b).to eq 600
    end
  end
end
