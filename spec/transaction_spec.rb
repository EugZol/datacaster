RSpec.describe Datacaster::Transaction do
  include Dry::Monads[:result]

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

  it "allows to use instance methods as steps" do
    tx =
      Class.new do
        include Datacaster::Transaction

        perform_partial do
          steps(
            transform(&unwrap),
            cast(&typecast),
            with(:email, transform(&send_email))
          )
        end

        def unwrap(x)
          @user_id = 123
          x.to_h
        end

        def typecast(x)
          Datacaster.schema do
            hash_schema(name: string, email: string)
          end.(x)
        end

        def send_email(email)
          {address: email, result: true, id: @user_id}
        end
      end

    expect(tx.(name: 'John', email: 'john@example.org').to_dry_result).to eq Success(
      name: 'John',
      email: {address: 'john@example.org', result: true, id: 123}
    )
  end

  it "allows imperative-style notation" do
    tx =
      Class.new do
        include Datacaster::Transaction

        def perform(value)
          value = unwrap(value)
          value = step! { typecast(value) }
          value[:email] = step { check_email(value[:email]) }.value_or("/dev/null")
          value[:email] = send_email(value[:email])

          Datacaster.ValidResult(value)
        end

        def unwrap(x)
          @user_id = 123
          x.to_h
        end

        def typecast(x)
          Datacaster.schema do
            hash_schema(name: string, email: string)
          end.(x)
        end

        def check_email(email)
          Datacaster.schema { check { |email| email == 'john@example.org' } }.(email)
        end

        def send_email(email)
          {address: email, result: true, id: @user_id}
        end
      end

    expect(tx.(name: 'John', email: 'john@example.org').to_dry_result).to eq Success(
      name: 'John',
      email: {address: 'john@example.org', result: true, id: 123}
    )

    expect(tx.(name: 'John', email: 5).to_dry_result).to eq Failure(
      email: ['is not a string']
    )

    expect(tx.(name: 'John', email: 'abc').to_dry_result).to eq Success(
      name: 'John',
      email: {address: '/dev/null', result: true, id: 123}
    )
  end
end
