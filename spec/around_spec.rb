RSpec.describe Datacaster do
  include Dry::Monads[:result]

  describe "around casters" do
    it "casts around with #cast_around" do
      side_effect = []
      schema =
        Datacaster.schema do
          push_1_2 = cast_around do |value, steps|
            side_effect << 1
            result = steps.(3)
            side_effect << 2
            Datacaster::ValidResult(:other)
          end

          push_1_2.around(
            run { |value| side_effect << value },
            run { |value| side_effect << value }
          )
        end

      expect(schema.(:something).to_dry_result).to eq Success(:other)
      expect(side_effect).to eq [1, 3, 3, 2]
    end
  end
end
