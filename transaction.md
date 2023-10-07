# Datacaster transaction

As an experimental feature a "transaction" is available: datacaster defined as a class.

## Example

```ruby
require 'datacaster'

class UserRegistration
  include Datacaster::Transaction

  perform do
    steps(
      transformer(:prepare),
      typecast,
      with(:email, transformer(:send_email))
    )
  end

  define_steps do
    def typecast = hash_schema(name: string, email: string)
  end

  def initialize(user_id = 123)
    @user_id = user_id
  end

  def prepare(x)
    @user_id ||= 123
    x.to_h
  end

  def send_email(email)
    {address: email, sent: true, id: @user_id}
  end
end

UserRegistration.(name: 'John', email: 'john@example.org')
# => Datacaster::ValidResult({:name=>"John", :email=>{:address=>"john@example.org", :result=>true, :id=>123}})
```

## Structure

Transaction is just a class which includes `Datacaster::Transaction`. Upon inclusion, all datacaster predefined methods are added as class methods.

Call `.perform(a_caster)` or `.perform { a_caster }` (where `caster` is a Datacaster instance) to define how transaction performs. Transaction instance will behave as a normal datacaster (i.e. `a_caster` itself) with some enhancements.

Firstly, transaction class has `.call` method which will initialize instance (available only if `#initialize` doesn't have required arguments) and pass arguments to the instance's `#call`.

Secondly, runtime-context for casters used in a transaction is the transaction instance itself. You can call transaction instance methods and get/set transaction instance variables inside blocks of `check { ... }`, `cast { ... }` and all the other predefined datacaster methods. That's why `@user_id` works in the example above.

Thirdly, convenience method `define_steps` is added, which is just a better looking `class << self`.

Lastly, convenience methods `caster(:m)`, `checker(:m)`, `comparator(:m)`, `transformer(:m)` are added. These methods create a `cast { ... }`, `check { ... }`, `compare { ... }` or `transform { ... }` caster from the transaction's instance method `m`.

Instead, of course, just `cast { m }` and so on could be used.

Note that `steps` is a predefined Datacaster method (which works as `&`), and so is `with`. They are not Transaction-specific enhancements.

## Around steps with `cast_around`

An experimental addition to Datacaster convenient for the use in Transaction is `cast_around` – a way to wrap a number of steps inside some kind of setup/rollback block, e.g. a database transaction.

```ruby
class UserRegistration
  include Datacaster::Transaction

  perform do
    steps(
      run { prepare },
      inside_transaction.around(
        run { register },
        run { create_account }
      ),
      run { log }
    )
  end

  define_steps do
    def inside_transaction = cast_around do |value, inner|
      puts "DB transaction started"
      result = inner.(value)
      puts "DB transaction ended"

      result
    end
  end

  def prepare
    puts "Preparing"
  end

  def register
    puts "User is registered"
  end

  def create_account
    puts "Account has been created"
  end

  def log
    puts "Creating log entry"
  end
end

UserRegistration.('a user object')
# Preparing
# DB transaction started
# User is registered
# Account has been created
# DB transaction ended
# Creating log entry
# => #<Datacaster::ValidResult("a user object")>
```

As shown in the example, `cast_around { |value, inner| ...}.around(*casters)` works in the following manner: it yields incoming value as the first argument (`value`) and casters specified in `.around(...)` part as the second argument (`inner`) to the block given. Casters are automatically joined with `steps` if there are more than one.

Block may call `steps.(value)` to execute casters in a regular manner. Block must return a kind of `Datacaster::Result`. `steps.(...)` will always return `Datacaster::Result`, so that result could be passed as a `cast_around` result, as shown in the example.