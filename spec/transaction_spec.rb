RSpec.describe Datacaster::Transaction do
  include Dry::Monads[:result]

  before(:all) do
    @i18n_module = Datacaster::Config.i18n_module
    Datacaster::Config.i18n_module = Datacaster::SubstituteI18n
  end

  after(:all) do
    Datacaster::Config.i18n_module = @i18n_module
  end

  it "returns true for Datacaster.instance?" do
    tx =
      Class.new do
        include Datacaster::Transaction
      end

    expect(Datacaster.instance?(tx.new)).to eq true
  end

  it "performs basic casting with Datacaster::Predefined casters" do
    tx =
      Class.new do
        include Datacaster::Transaction

        perform integer
      end

    expect(tx.new.(5).to_dry_result).to eq Success(5)
    expect(tx.(5).to_dry_result).to eq Success(5)
  end

  it "performs multi-step casting" do
    tx =
      Class.new do
        include Datacaster::Transaction

        unwrap = transform { |x| x.to_h }
        typecast = hash_schema(name: string, email: string)
        send_email = transform do |email|
          {address: email, result: true}
        end

        perform steps(
          unwrap,
          typecast,
          with(:email, send_email)
        )
      end

    expect(tx.(name: 'John', email: 'john@example.org').to_dry_result).to eq Success(
      name: 'John',
      email: {address: 'john@example.org', result: true}
    )
  end
end
