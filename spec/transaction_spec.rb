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

  it "allows to define steps in a block" do
    tx =
      Class.new do
        include Datacaster::Transaction

        perform { steps(
          unwrap,
          typecast,
          with(:email, send_email)
        ) }

        define_steps do
          # Ruby 3: def unwrap = ...
          def unwrap; transform { |x| x.to_h }; end
          def typecast; hash_schema(name: string, email: string); end
          def send_email
            transform do |email|
              {address: email, result: true}
            end
          end
        end
      end

    expect(tx.(name: 'John', email: 'john@example.org').to_dry_result).to eq Success(
      name: 'John',
      email: {address: 'john@example.org', result: true}
    )
  end

  it "allows to define steps in a block" do
    return pending
    tx =
      Class.new do
        include Datacaster::Transaction

        transform_step :unwrap
        cast_step typecast
        cast_step with(:email, send_email)
        perform { sequence(
          unwrap,
          typecast,
          with(:email, send_email)
        ) }

        steps.unwrap = transform { |x| x.to_h }
        steps.typecast = hash_schema(name: string, email: string)
        steps.send_email = transform do |email|
          {address: email, result: true}
        end
      end

    expect(tx.(name: 'John', email: 'john@example.org').to_dry_result).to eq Success(
      name: 'John',
      email: {address: 'john@example.org', result: true}
    )
  end
end
