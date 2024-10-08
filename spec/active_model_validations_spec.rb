RSpec.describe Datacaster do
  include Dry::Monads[:result]

  describe 'active model validations' do
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
end
