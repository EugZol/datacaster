# Datacaster

This gem provides run-time type checking and mapping of composite data structures (i.e. hashes/arrays of hashes/arrays of ... of literals).

Its main use is in the validation and preliminary transformation of API params requests.


# Table of contents

- [Installing](#installing)
- [Why not ...](#why-not-)
- [Basics](#basics)
  - [Conveyor belt](#conveyor-belt)
  - [Result value](#result-value)
  - [Hash schema](#hash-schema)
  - [Logical operators](#logical-operators)
    - [*AND operator*:](#and-operator)
    - [*OR operator*:](#or-operator)
    - [*IF... THEN... ELSE operator*:](#if-then-else-operator)
- [Built-in types](#built-in-types)
  - [Basic types](#basic-types)
    - [`string`](#string)
    - [`integer`](#integer)
    - [`float`](#float)
    - [`decimal([digits = 8])`](#decimaldigits--8)
    - [`array`](#array)
    - [`hash_value`](#hash_value)
  - [Convenience types](#convenience-types)
    - [`non_empty_string`](#non_empty_string)
    - [`hash_with_symbolized_keys`](#hash_with_symbolized_keys)
    - [`integer32`](#integer32)
  - [Special types](#special-types)
    - [`absent`](#absent)
    - [`any`](#any)
    - [`transform_to_value(value)`](#transform_to_valuevalue)
    - [`remove`](#remove)
    - [`pass`](#pass)
    - [`responds_to(method)`](#responds_tomethod)
    - [`must_be(klass)`](#must_beklass)
    - [`optional(base)`](#optionalbase)
    - [`pick(key)`](#pickkey)
    - [`merge_message_keys(*keys)`](#merge_message_keyskeys)
  - ["Web-form" types](#web-form-types)
    - [`to_integer`](#to_integer)
    - [`to_float`](#to_float)
    - [`to_boolean`](#to_boolean)
    - [`iso8601`](#iso8601)
    - [`optional_param(base)`](#optional_parambase)
  - [Custom and fundamental types](#custom-and-fundamental-types)
    - [`cast(name = 'Anonymous') { |value| ... }`](#castname--anonymous--value--)
    - [`check(name = 'Anonymous', error = 'is invalid') { |value| ... }`](#checkname--anonymous-error--is-invalid--value--)
    - [`try(name = 'Anonymous', error = 'is invalid', catched_exception:) { |value| ... }`](#tryname--anonymous-error--is-invalid-catched_exception--value--)
    - [`validate(active_model_validations, name = 'Anonymous')`](#validateactive_model_validations-name--anonymous)
    - [`compare(reference_value, name = 'Anonymous', error = nil)`](#comparereference_value-name--anonymous-error--nil)
    - [`transform(name = 'Anonymous') { |value| ... }`](#transformname--anonymous--value--)
    - [`transform_if_present(name = 'Anonymous') { |value| ... }`](#transform_if_presentname--anonymous--value--)
  - [Passing additional context to schemas](#passing-additional-context-to-schemas)
  - [Array schemas](#array-schemas)
  - [Hash schemas](#hash-schemas)
    - [Absent is not nil](#absent-is-not-nil)
    - [Schema vs Partial schema](#schema-vs-partial-schema)
    - [AND with error aggregation (`*`)](#and-with-error-aggregation-)
  - [Shortcut nested definitions](#shortcut-nested-definitions)
  - [Mapping hashes: `transform_to_hash`](#mapping-hashes-transform_to_hash)
- [Error remapping](#error-remapping)
- [Registering custom 'predefined' types](#registering-custom-predefined-types)
- [Contributing](#contributing)
- [Ideas/TODO](#ideastodo)
- [License](#license)

## Installing

Add to your Gemfile:

```
gem 'datacaster'
```

## Why not ...

**Why not Rails strong params**?

Strong params don't provide easy composition of validations and are restricted in error (failure) reporting.

**Why not ActiveModel validations**?

ActiveModel requires a substantial amount of boilerplate (e.g. separate class for each of nested objects/hashes) and is limited in composition.

**Why not [Dry Types](https://dry-rb.org/gems/dry-types)?**

Poor validation error reporting, a substantial amount of boilerplate, arguably complex/inconsistent DSL.

## Basics

### Conveyor belt

Datacaster could be thought of as a conveyor belt, where each step of the conveyor either performs some validation of a value or some transformation of it.

For example, the following code validates that value is a string:

```ruby
require 'datacaster'

validator = Datacaster.schema { string }

validator.("test")        # Datacaster::ValidResult("test")
validator.("test").valid? # true
validator.("test").value  # "test"
validator.("test").errors # nil

validator.(1)             # Datacaster::ErrorResult(["must be string"])
validator.(1).valid?      # false
validator.(1).value       # nil
validator.(1).errors      # ["must be string"]
```

Datacaster instances are created with a call to `Datacaster.schema { ... }`, `Datacaster.partial_schema { ... }` or `Datacaster.choosy_schema { ... }` (described later in this file).

Datacaster validators' results could be converted to [dry result monad](https://dry-rb.org/gems/dry-monads/1.0/result/):

```ruby
require 'datacaster'

validator = Datacaster.schema { string }

validator.("test").to_dry_result # Success("test")
validator.(1).to_dry_result      # Failure(["must be string"])
```

`string` method call inside of the block in the examples above returns (with the help of some basic meta-programming magic) 'chainable' datacaster instance. To 'chain' datacaster instances 'logical AND' (`&`) operator is used:

```ruby
require 'datacaster'

validator = Datacaster.schema { string & check { |x| x.length > 5 } }

validator.("test1") # Datacaster::ValidResult("test12")
validator.(1)       # Datacaster::ErrorResult(["must be string"])
validator.("test")  # Datacaster::ErrorResult(["is invalid"])
```

In the code above we ensure that validated value is:

a) a string,  
b) has length > 5.

If first condition is not met, second one is not evaluated at all (i.e. evaluation is always "short-circuit", just as one might expect).

Later in this file `string` and other such validations are referred to as "basic types", and `check { ... }` and other custom validations are referred to as "custom types".

It is worth noting that in `a & b` validation composition as above, if `a` in some way transforms the value and passes, then `b` receives the transformed value (though `string` validation in particular guarantees to not change the initial value).

### Result value

All datacaster validations, when called, return an instance of `Datacaster::Result` value, i.e. `Datacaster::ValidResult` or `Datacaster::ErrorResult`.

You can call `#valid?`, `#value`, `#errors` methods directly, or, if preferred, call `#to_dry_result` method to convert `Datacaster::Result` to the corresponding `Dry::Monads::Result` (with all the included "batteries" of the latter, e.g. pattern matching, 'binding', etc.).

`#value` and `#errors` would return `#nil` if the result is, correspondingly, `ErrorResult` and `ValidResult`. No methods would raise an error.

Errors are returned as array or hash (or hash of arrays, or array of hashes, etc., for complex data structures). Each element of the returned array shows a separate error (as a string), and each key of the returned hash corresponds to the key of the validated hash. More or less errors are similar to what you expect from `ActiveModel::Errors#to_hash`.

### Hash schema

Validating hashes is the main case scenario for datacaster. Several specific conventions are used here, which are listed below in this file.

Let's assume we want to validate that a hash (which represents data about a person):

a) is, in fact, a Hash;  
b) has exactly 2 keys, `name` and `salary`,  
c) key 'name' is a string,  
d) key 'salary' is an integer:

```ruby
person_validator =
  Datacaster.schema do
    hash_schema(
      name: string,
      salary: integer
    )
  end

person_validator.(name: "Jack Simon", salary: 50_000)
# => Datacaster::ValidResult({:name=>"Jack Simon", :salary=>50000})

person_validator.(name: "Jack Simon")
# => Datacaster::ErrorResult({:salary=>["must be integer"]})

person_validator.("test")
# => Datacaster::ErrorResult(["must be hash"])

person_validator.(name: "John Smith", salary: "1000")
# => Datacaster::ErrorResult({:salary=>["must be integer"]})

person_validator.(name: :john, salary: "1000")
# => Datacaster::ErrorResult({:name=>["must be string"], :salary=>["must be integer"]})

person_validator.(name: "John Smith", salary: 100_000, title: "developer")
# => Datacaster::ErrorResult({:title=>["must be absent"]})
```

`Datacaster.schema` definitions don't permit, as you likely noticed from the example above, extra fields in the hash. In fact, `Datacaster.schema` automatically adds special built-in validator, called `Datacaster::Terminator::Raising`, at the end of your validation chain, which function is to ensure that all hash keys had been validated.

If you want to permit your hashes to contain extra fields, use `Datacaster.partial_schema` (it's the only difference between `.schema` and `.partial_schema`):

```ruby
person_with_extra_keys_validator =
  Datacaster.partial_schema do
    hash_schema(
      name: string,
      salary: integer
    )
  end

person_with_extra_keys_validator.(name: "John Smith", salary: 100_000, title: "developer")
# => Datacaster::ValidResult({:name=>"John Smith", :salary=>100000, :title=>"developer"})
```

Also if you want to delete extra fields, use `Datacaster.choosy_schema`:

```ruby
person_with_extra_keys_validator =
  Datacaster.choosy_schema do
    hash_schema(
      name: string,
      salary: integer
    )
  end

person_with_extra_keys_validator.(name: "John Smith", salary: 100_000, age: 18)
# => Datacaster::ValidResult({:name=>"John Smith", :salary=>100000})
```

Datacaster 'hash schema' makes strict difference between absent and nil values, allows to use shortcuts for defining nested schemas (with no limitation on the level of nesting), and has convinient 'AND with error aggregation' (`*`, same symbol as in numbers multiplication) for joining validation errors of multiple failures. See below in the corresponding sections.

### Logical operators

There are 3 regular 'logical operators':

* AND (`&`)
* OR (`|`)
* IF... THEN... ELSE

And one special: AND with error aggregation (`*`).

The former 3 is described immediately below, and the latter is described in the section on hash schemas further in this file.

#### *AND operator*:

```ruby
even_number = Datacaster.schema { integer & check { |x| x.even? } }

even_number.(2)
# => Datacaster::ValidResult(2)

even_number.(3)
# => Datacaster::ErrorResult(["is invalid"])
even_number.("test")
# => Datacaster::ErrorResult(["must be integer"])
```

If left-hand validation of AND operator passes, *its result* (not the original value) is passed to the right-hand validation. See below in this file section on transformations where this might be relevant.

#### *OR operator*:

```ruby
# 'compare' custom type returns ValidResult if and only if validated value == compare's argument
person_or_entity = Datacaster.schema { compare(:person) | compare(:entity) }

person_or_entity.(:person) # => Datacaster::ValidResult(:person)
person_or_entity.(:entity) # => Datacaster::ValidResult(:entity)

person_or_entity.(:ngo)    # => Datacaster::ErrorResult(["must be equal to :entity"])
```

Notice that OR operator, if left-hand validation fails, passes the original value to the right-hand validation. As you see in the example above resultant error messages are not always convenient (i.e. to show something like "value must be :person or :entity" is preferable to showing somewhat misleading "must be equal to :entity"). See the next section on "IF... THEN... ELSE" for closer to the real world example.

#### *IF... THEN... ELSE operator*:

Let's suppose we want to validate that incoming hash is either 'person' or 'entity', where

- 'person' is a hash with 3 keys (kind: `:person`, name: string, salary: integer),
- 'entity' is a hash with 4 keys (kind: `:entity`, title: string, form: string, revenue: integer).

```ruby
person_or_entity =
  Datacaster.schema do
    # separate 'kind' validator, ensures that 'kind' is either :person or :entity
    kind_is_valid = hash_schema(
      kind: check { |x| %i[person entity].include?(x) }
    )

    # separate person validator (excluding validation of 'kind' field)
    person = hash_schema(name: string, salary: integer)

    # separate entity validator (excluding validation of 'kind' field)
    entity = hash_schema(title: string, form: string, revenue: integer)

    kind_is_valid & hash_schema(kind: compare(:person)).then(person).else(entity)
  end

person_or_entity.(
  kind: :person,
  name: "John Smith",
  salary: 100_000
)
# => Datacaster::ValidResult({:kind=>:person, :name=>"John Smith", :salary=>100000})

person_or_entity.(
  kind: :entity,
  title: "Hooves and Hornes",
  form: "LLC",
  revenue: 5_000_000
)
# => Datacaster::ValidResult({:kind=>:entity, :title=>"Hooves and Hornes", :form=>"LLC", :revenue=>5000000})

person_or_entity.(
  title: "?"
)
# => Datacaster::ErrorResult({:kind=>["is invalid"]})
```

See below documentation on 'check' custom type to know how to provide custom error message instead of 'is invalid'.

Schema, defined above, behaves in all aspects (shown in the example and in other practical applications which might come to your mind) just as you might expect it to, after reading previous examples and the code above.

In our opinion the above example shows most laconic way to express underlying 'business-logic' (including elaborate error reporting on all kinds of failures) among all available competitor approaches/gems.

Formally, with `a.then(b).else(c)`:

* if `a` returns `ValidResult`, then `b` is called *with the result of `a`* (not the original value) and whatever `b` returns is returned;
* otherwise, `c` is called with the original value, and whatever `c` returns is returned.

`else`-part is required and could not be omitted.

Note: this construct is *not* an equivalent of `a & b | c`.

With `a.then(b).else(c)` if `a` and `b` fails, then `b`'s error is returned. With `a & b | c`, instead, `c`'s result would be returned.

## Built-in types

Full description of all built-in types follows.

### Basic types

#### `string`

Returns ValidResult if and only if provided value is a string. Doesn't transform the value.

#### `integer`

Returns ValidResult if and only if provided value is an integer. Doesn't transform the value.

#### `float`

Returns ValidResult if and only if provided value is a float (checked with Ruby's `#is_a?(Float)`, i.e. integers are not considered valid floats). Doesn't transform the value.

#### `decimal([digits = 8])`

Returns ValidResult if and only if provided value is either a float, integer or string representing float/integer.

Transforms the value to `BigDecimal` instance.

#### `array`

Returns ValidResult if and only if provided value is an `Array`. Doesn't transform the value.

#### `hash_value`

Returns ValidResult if and only if provided value is a `Hash`. Doesn't transform the value.

Note: this type is called `hash_value` instead of `hash`, because `hash` is reserved method name in Ruby.

### Convenience types

#### `non_empty_string`

Returns ValidResult if and only if provided value is a string and is not empty. Doesn't transform the value.

#### `hash_with_symbolized_keys`

Returns ValidResult if and only if provided value is an instance of `Hash`. Transforms the value to `#hash_with_symbolized_keys` (requires `ActiveSupport`).

#### `integer32`

Returns ValidResult if and only if provided value is an integer and it's absolute value is <= 2_147_483_647. Doesn't transform the value.

### Special types

#### `absent`

Returns ValidResult if and only if provided value is `Datacaster.absent` (this is singleton instance). Relevant only for hash schemas (see below). Doesn't transform the value.

#### `any`

Returns ValidResult if and only if provided value is not `Datacaster.absent` (this is singleton instance). Relevant only for hash schemas (see below). Doesn't transform the value.

#### `transform_to_value(value)`

Always returns ValidResult. The value is transformed to provided argument. Is used to provide default values, e.g.:

```ruby
max_concurrent_connections = Datacaster.schema { compare(nil).then(transform_to_value(5)).else(integer) }

max_concurrent_connections.(9)   # => Datacaster::ValidResult(9)
max_concurrent_connections.("9") # => Datacaster::ErrorResult(["must be integer"])
max_concurrent_connections.(nil) # => Datacaster::ValidResult(5)
```

#### `remove`

Equivalent to `transform_to_value(Datacaster.absent)`. Always returns ValidResult. The value is transformed to `Datacaster.absent` (see section below on hash schemas, where this is useful).

#### `pass`

Equivalent to `transform_to_value { |x| x }`. Always returns ValidResult. Doesn't transform the value. Useful to "mark" the value as validated (see section below on hash schemas, where this could be applied).

#### `responds_to(method)`

Returns ValidResult if and only if value `#responds_to?(method)`. Doesn't transform the value.

#### `must_be(klass)`

Returns ValidResult if and only if value `#is_a?(klass)`. Doesn't transform the value.

#### `optional(base)`

Returns ValidResult if and only if value is either `Datacaster.absent` (singleton instance) or passes `base` validation. See below documentation on hash schemas for details on `Datacaster.absent`.

```ruby
item_with_optional_price =
    Datacaster.schema do
      hash_schema(
        name: string,
        price: optional(float)
      )
    end

item_with_optional_price.(name: "Book", price: 1.23)
# => Datacaster::ValidResult({:name=>"Book", :price=>1.23})
item_with_optional_price.(name: "Book")
# => Datacaster::ValidResult({:name=>"Book"})

item_with_optional_price.(name: "Book", price: "wrong")
# => Datacaster::ErrorResult({:price=>["must be float"]})
```

#### `pick(key)`

Returns ValidResult if and only if value `#is_a?(Enumerable)`.

Transforms the value to/returns:

* `value[key]` if key is set in the value
* `nil` if `value[key]` is set and is nil
* `Datacaster.absent` if key is not set

```ruby
pick_name = Datacaster.schema { pick(:name) }

pick_name.(name: "George")       # => Datacaster::ValidResult("George")
pick_name.(last_name: "Johnson") # => Datacaster::ValidResult(#<Datacaster.absent>)

pick_name.("test")               # => Datacaster::ErrorResult(["must be Enumerable"])
```

Alternative form could be used: `pick(*keys)`.

In this case, an array of results is returned, each element in which corresponds to the element in `keys` array (i.e. is an argument of the `pick`) and evaluated in accordance with the above rules.

```ruby
pick_name_and_age = Datacaster.schema { pick(:name, :age) }

pick_name_and_age.(name: "George", age: 20)       # => Datacaster::ValidResult(["George", 20])
pick_name_and_age.(last_name: "Johnson", age: 20) # => Datacaster::ValidResult([#<Datacaster.absent>, 20])

pick_name_and_age.("test")                        # => Datacaster::ErrorResult(["must be Enumerable"])
```

#### `merge_message_keys(*keys)`

Returns ValidResult only if value `#is_a?(Hash)`.

Maps incoming hash to Datacaster styled messages.

```ruby
mapper =
  Datacaster.schema do
    merge_message_keys(:a, :b)
  end

mapper.(a: "1", b: "2") # => Datacaster::ValidResult(["1", "2"])
```

Arrays are merged. Merging `["1", "2"]` and `["2", "3"]` will produce `["1", "2", "3"]`.

Hash values are merged recursively (deeply) with one another:

```ruby
mapper = Datacaster.schema do
  transform_to_hash(
    resourse: merge_message_keys(:resourse),
    user: merge_message_keys(:user, :login_params),
    login_params: remove
  )
end

mapper.(
  resourse: "request was rejected",
  user: {
    age: "too young", password: "too long"
  },
  login_params: {
    password: "should contain special characters",
    nickname: "too short"
  }
)
# => Datacaster::ValidResult({
#     :resourse=>["request was rejected"],
#     :user=>{
#       :age=>["too young"],
#       :password=>["too long", "should contain special characters"],
#       :nickname=>["too short"]
#     }
#   })
```

Hash value merges non-Hash value by merging it with `:base` key (added if absent):

```ruby
mapping = Datacaster.schema do
  transform_to_hash(
    resourse: merge_message_keys(:resourse),
    user: merge_message_keys(:user, :user_error),
    user_error: remove
  )
end

mapping.(
  resourse: "request was rejected",
  user: {age: "too young", nickname: "too long"},
  user_error: "user is invalid"
)
# => Datacaster::ValidResult({
#      :resourse=>["request was rejected"],
#      :user=>{
#        :age=>["too young"],
#        :nickname=>["too long"],
#        :base=>["user is invalid"]
#      }
# })
```

Hash keys with `nil` and `[]` values are deeply ignored:

```ruby
mapping = Datacaster.schema do
  transform_to_hash(
    user: merge_message_keys(:user),
  )
end

mapping.(
  user: {
    age: "too young", nickname: [], user_error: nil
  }
)
# => Datacaster::ValidResult({
#      :user=> {
#        :age=>["too young"]
#      }
#    })
```

### "Web-form" types

These types are convenient to parse and validate POST forms and decode JSON requests.

#### `to_integer`

Returns ValidResult if and only if value is an integer, float or string representing integer/float. Transforms value to integer.

#### `to_float`

Returns ValidResult if and only if value is an integer, float or string representing integer/float. Transforms value to float.

#### `to_boolean`

Returns ValidResult if and only if value is `true`, `1`, `'true'` or `false`, `0`, `'false'`. Transforms value to `true` or `false` (using apparent convention).

#### `iso8601`

Returns ValidResult if and only if value is a string in [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) date-time format.

```ruby
dob = Datacaster.schema { iso8601 }

dob.("2011-02-03")
# => Datacaster::ValidResult(#<DateTime: 2011-02-03T00:00:00+00:00 ...>)
```

Transforms value to `DateTime` instance.

#### `optional_param(base)`

Returns ValidResult if and only if value is absent, empty string or passes `base` validation.

If the value is empty string (`""`), transforms it to `Datacaster.absent` instance. It makes sense to use this type only in conjunction with hash schema validations (see below), where `Datacaster.absent` keys are removed from the resultant hash.

Otherwise, doesn't transform the value.

### Custom and fundamental types

These custom types (or 'meta' types) are used to create 'hand-crafted' validators.

When `name` argument is available, that argument determines what would display with `#inspect` of that validator (and nothing else).

When `error` argument is available, that argument determines what error text (should be string, but actual error will automatically be displayed as array of strings, see examples in the previous sections of this file) will be used if validation fails.

#### `cast(name = 'Anonymous') { |value| ... }`

The most basic &mdash; "fully manual" &mdash; validator.

Calls block with the value. Returns whatever block returns.

Provided block must return either `Datacaster::Result` or `Dry::Result::Monad` (the latter will automatically be converted to the former), otherwise `cast` will raise runtime `TypeError`.

```ruby
# Actually, better use 'check' here instead (see below)
user_id_exists =
  Datacaster.schema do
    cast('UserIdExists') do |user_id|
      if User.exists?(user_id)
        Success(user_id) # or Datacaster::ValidResult(user_id)
      else
        # Note: actual returned error will always be an array, despite what
        # you manually set as return value of caster. E.g., ["user is not found"]
        # in this example.
        Failure("user is not found") # or Datacaster::ErrorResult("user is not found")
      end
    end
  end
```

Notice, that for this example (as is written in the comment) `check` type is better option (see below). It's actually so hard to come up with an example where explicit `cast` is the best option that we didn't manage to do that. Refrain from using `cast` unless absolutely no other type could be used.

`cast` will transform value, if such is the logic of provided block.

#### `check(name = 'Anonymous', error = 'is invalid') { |value| ... }`

Returns ValidResult if and only if provided block returns truthy value (i.e. anything except `false` and `nil`).

```ruby
user_id_exists =
  Datacaster.schema do
    check('UserIdExists', 'user is not found') do |user_id|
      User.exists?(user_id)
    end
  end
```

Doesn't transform the value.

#### `try(name = 'Anonymous', error = 'is invalid', catched_exception:) { |value| ... }`

Returns ValidResult if and only if block finishes without exceptions. If block raises an exception:

* if exception class equals to `catched_exception`, then ErrorResult is returned;
* otherwise, exception is re-raised.

Note: instead of specific exception class an array of classes could be provided.

```ruby
def dangerous_method!
  raise RuntimeError
end

dangerous_validator =
  Datacaster.schema do
    try(catched_exception: RuntimeError) { |value| dangerous_method! }
  end
```

As you see from the example, that's another 'meta type', which direct use is hard to justify. Consider using `check` instead (returning boolean value from the block instead of raising error).

Doesn't transform the value.

#### `validate(active_model_validations, name = 'Anonymous')`

Requires ActiveModel.

Add `require 'datacaster/validator'` to your source code before using this.

Returns ValidResult if and only if provided ActiveModel validations passes. Otherwise, returns ActiveModel errors wrapped as ErrorResult.

```ruby
require 'datacaster/validator'

nickname =
  Datacaster.schema do
    validate(format: {
      with: /\A[a-zA-Z]+\z/,
      message: "only allows letters"
    })
  end

nickname.("longshot") # Datacaster::ValidResult("longshot")
nickname.("user32")   # Datacaster::ErrorResult(["only allows letters"])
```

Doesn't transform the value.

#### `compare(reference_value, name = 'Anonymous', error = nil)`

This type is the way to ensure some value in your schema is some predefined "constant".

Returns ValidResult if and only if `reference_value` equals value.

```ruby
agreed_with_tos =
  Datacaster.partial_schema do
    hash_schema(
      agreed: compare(true)
    )
  end
```

#### `transform(name = 'Anonymous') { |value| ... }`

Always returns ValidResult. Transforms the value: returns whatever block returned, automatically wrapping it into `ValidResult`.

```ruby
city =
  Datacaster.schema do
    hash_schema(
      name: string,
      # convert miles to km
      distance: to_float & transform { |v| v * 1.60934 }
    )
  end

city.(name: "Denver", distance: "2.5") # => Datacaster::ValidResult({:name=>"Denver", :distance=>4.02335})
```

#### `transform_if_present(name = 'Anonymous') { |value| ... }`

Always returns ValidResult. If the value is `Datacaster.absent` (singleton instance, see below section on hash schemas), then `Datacaster.absent` is returned (block isn't called). Otherwise, works like `transform`.

###  Passing additional context to schemas

You can pass `context` to schema using `.with_context` method

```ruby
# class User < ApplicationRecord
#  ...
# end
#
# class Post < ApplicationRecord
#   belongs_to :user
#   ...
# end

schema =
  Datacaster.schema do
    hash_schema(
      post_id: to_integer & check { |id| Post.where(id: id, user_id: context.current_user).exists? }
    )
  end

current_user = ...

schema.with_context(current_user: current_user).(post_id: 15)
```

`context` is an [OpenStruct](https://ruby-doc.org/stdlib-3.1.0/libdoc/ostruct/rdoc/OpenStruct.html) instance which is initialized in `.with_context`

**Note**

`context` can be accesed only in types' blocks:
```ruby
mail_transformer = Datacaster.schema { transform { |v| "#{v}#{context.postfix}" } }

mail_transformer.with_context(postfix: "@domen.com").("admin")
# => #<Datacaster::ValidResult("admin@domen.com")>
```
It can't be used in schema definition block itself:
```ruby
Datacaster.schema { context.error }
# leads to `NoMethodError`
```

### Array schemas

To define compound data type, array of 'something', use `array_schema(something)` (or, synonymically, `array_of(something)`). There is no way to define array wherein each element is of different type.

```ruby
salaries = Datacaster.schema { array_of(integer) }

salaries.([1000, 2000, 3000]) # Datacaster::ValidResult([1000, 2000, 3000])

salaries.(["one thousand"])   # Datacaster::ErrorResult({0=>["must be integer"]})
salaries.(:not_an_array)      # Datacaster::ErrorResult(["must be array"])
salaries.([])                 # Datacaster::ErrorResult(["must not be empty"])
```

To allow empty array use the following construct: `compare([]) | array_of(...)`.

If you want to define array of hashes, shortcut definition could be used: instead of `array_of(hash_schema({...}))` use `array_of({...})`:

```ruby
people =
  Datacaster.schema do
    array_of(
      # hash_schema(
      {
        name: string,
        salary: float
      }
      # )
    )
  end

person1 = {name: "John Smith", salary: 250_000.0}
person2 = {name: "George Johnson", salary: 50_000.0}
people.([person1, person2]) # => Datacaster::ValidResult([{...}, {...}])

people.([{salary: 250_000.0}, {salary: "50000"}])
# => Datacaster::ErrorResult({
#   0 => {:name => ["must be string"]},
#   1 => {:name => ["must be string"], :salary => ["must be float"]}
# })
```

Notice, that extra keys of inner hashes could be validated only if each element is otherwise valid. In other words, if some of the elements have other validation errors, then "extra key must be absent" validation error won't appear on any element.

Formally, `array_of(x)` will return ValidResult if and only if:

a) provided value implements basic array methods (`#map`, `#zip`),  
b) provided value is not `#empty?`,  
c) each element of the provided value passes validation of `x`.

If a) fails, `ErrorResult(["must be array"])` is returned.  
If b) fails, `ErrorResult(["must not be empty"])` is returned.  
If c) fails, `ErrorResult({0 => ..., 1 => ...})` is returned. Wrapped hash contains keys which correspond to initial array's indices, and values correspond to failure returned from `x` validator, called for the corresponding element.

Array schema transforms array if inner type (`x`) transforms element (in this case `array_schema` works more or less like `map` function). Otherwise, it doesn't transform.

### Hash schemas

Hash schemas are "bread and butter" of Datacaster.

To define compound data type, hash of 'something', use `hash_schema({key: type, ...})`:

```ruby
person =
  Datacaster.schema do
    hash_schema(
      name: string,
      salary: integer
    )
  end

person.(name: "John Smith", salary: 100_000)
# => Datacaster::ValidResult({:name=>"John Smith", :salary=>100000})

person.(name: "John Smith", salary: "100_000")
# => Datacaster::ErrorResult({:salary=>["must be integer"]})
```

Formally, hash schema returns ValidResult if and only if:

a) provided value `is_a?(Hash)`,  
b) all values, fetched by keys mentioned in `hash_schema(...)` definition, pass corresponding validations,  
c) after all checks (including logical operators), there are no unchecked keys in the hash.

If a) fails, `ErrorResult(["must be hash"])` is returned.  
if b) fails, `ErrorResult(key1 => [errors...], key2 => [errors...])` is returned. Each key of wrapped "error hash" corresponds to the key of validated hash, and each value of "error hash" contains array of errors, returned by the corresponding validator.  
If b) fulfilled, then and only then validated hash is checked for extra keys. If they are found, `ErrorResult(extra_key_1 => ["must be absent"], ...)` is returned.

Technically, last part is implemented with special singleton validator, called `#<Datacaster::Terminator::Raising>`, which is automatically added to the validation chain (with the use of `&` operator) by `Datacaster.schema` method. Don't be scared if you see it in the output of `#inspect` method of your validators (e.g. in `irb`).

#### Absent is not nil

In practical tasks it's important to distinguish between absent (i.e. not set or deleted) and `nil` values of a hash.

To check some value for `nil`, use ordinary `compare(nil)` validator, mentioned above.

To check some value for absence, use `absent` validator:

```ruby
restricted_params =
  Datacaster.schema do
    hash_schema(
      username: string,
      is_admin: absent
    )
  end

restricted_params.(username: "test")
# => Datacaster::ValidResult({:username=>"test"})

restricted_params.(username: "test", is_admin: true)
# => Datacaster::ErrorResult({:is_admin=>["must be absent"]})
restricted_params.(username: "test", is_admin: nil)
# => Datacaster::ErrorResult({:is_admin=>["must be absent"]})
```

More practical case is to include `absent` validator in logical expressions, e.g. `something: absent | string`. If `something` is set to `nil`, this validation will fail, which could be the desired (and hardly achieved by any other validation framework) behavior.

Also, see documentation for `optional(base)` and `optional_param(base)` above. If some value becomes `Datacaster.absent` in its chain of validations-transformations, it is removed from the resultant hash (on the same stage where the lack of extra/unchecked keys in the hash is validated):

```ruby
person =
  Datacaster.schema do
    hash_schema(
      name: string,
      dob: optional(iso8601)
    )
  end

person.(name: "John Smith", dob: "1990-05-23")
# => Datacaster::ValidResult({:name=>"John Smith", :dob=>#<DateTime: 1990-05-23T00:00:00+00:00 ...>})
person.(name: "John Smith")
# => Datacaster::ValidResult({:name=>"John Smith"})

person.(name: "John Smith", dob: "invalid date")
# => Datacaster::ErrorResult({:dob=>["must be iso8601 string"]})
```

Another use-case for `Datacaster.absent` is to directly set some key to that value. In that case, it will be removed from the resultant hash. The most convenient way to do that is to use `remove` type (described above in this file):

```ruby
anonimized_person =
  Datacaster.schema do
    hash_schema(
      name: remove,
      dob: pass
    )
  end

anonimized_person.(name: "John Johnson", dob: "1990-05-23")
# => Datacaster::ValidResult({:dob=>"1990-05-23"})
```

Note: we need to `pass` `dob` field to "mark" it as validated, otherwise `Datacaster.schema` will return ErrorResult, notifying that unchecked extra field was in the initial hash.

#### Schema vs Partial schema

As written in the beginning of this section on `hash_schema`, at the last stage of validation it is ensured that hash contains no extra keys.

Sometimes it is necessary to omit that requirement and allow for hash to contain any keys (in addition to the ones defined in `hash_schema`). One practical use-case for that is when datacaster definitions are spread among several files.

Let's say we have:

* 'people' (hashes with `name: string`, `description: string` and `kind: 'person'` fields),
* 'entities' (hash with `title: string`, `description: string` and `kind: 'entity'` fields).

In other words, we have some polymorphic resource, which type is defined by `kind` field, and which has common fields for all its "sub-kinds" (in this example: `description`), and also fields specific to each "kind" (in database we often model this as [STI](https://api.rubyonrails.org/v6.0.3.2/classes/ActiveRecord/Base.html#class-ActiveRecord::Base-label-Single+table+inheritance)).

Here's how we would model this type with Datacaster (filenames are given for the sake of explanation, use whatever convention your project dictates; also, use whatever codestyle is preferred, below is shown the one which we prefer):

```ruby
# commmon_fields_validator.rb
CommonFieldsValidator =
  Datacaster.partial_schema do
    # validate common fields
    hash_schema(
      description: string
    )
  end

# person_validator.rb
PersonValidator =
  Datacaster.partial_schema do
    # validate fields specific to person
    hash_schema(
      name: string,
      kind: compare('person')
    )
  end

# entity_validator.rb
EntityValidator =
  Datacaster.partial_schema do
    # validate fields specific to entity
    hash_schema(
      title: string,
      kind: compare('entity')
    )
  end

# record_validator.rb
RecordValidator =
  Datacaster.schema do
    # separate validator for 'kind' field - to produce convenient error message
    kind = check("Kind", "must be either 'person' or 'enity'") do |v|
      %w(person entity).include?(v)
    end

    # check that 'kind' field is correct and then select validator
    # in accordance with it
    hash_schema(kind: kind) & CommonFieldsValidator &
      hash_schema(kind: compare('person')).
        then(PersonValidator).
        else(EntityValidator)
  end
```

See "IF... THEN... ELSE" section above in this file for full description of how `a.then(b).else(c)` validator works.

Examples of how this validator would work:

```ruby
# some_file.rb

RecordValidator.(
  kind: 'person',
  name: 'George Johnson',
  description: 'CEO'
)
# => Datacaster::ValidResult({:kind=>"person", :name=>"George Johnson", :description=>"CEO"})

RecordValidator.(kind: 'unknown')
# => Datacaster::ErrorResult({:kind=>["must be either 'person' or 'enity'"]})
RecordValidator.(
  kind: 'person',
  name: 'George Johnson',
  description: 'CEO',
  extra: :key
)
# => Datacaster::ErrorResult({:extra=>["must be absent"]})
```

Note that only the usage of `Datacaster.partial_schema` instead of `Datacaster.schema` allowed us to compose several `hash_schema`s from different files (from different calls to Datacaster API).

Had we used `schema` everywhere, `CommonFieldsValidator` would return failure for records which are supposed to be valid, because they would contain "extra" (i.e. not defined in `CommonFieldsValidator` itself) keys (e.g. `name` for person).

As a rule of thumb, use `partial_schema` in any "intermediary" validators (extracted for the sake of clarity of code and reusability) and use `schema` in any "end" validators (ones which receive full record as input and use intermediary validators behind the scenes).

#### AND with error aggregation (`*`)

Often it is useful to run validator which are "further down the conveyor" (i.e. placed at the right-hand side of AND operator `&`) even if current (i.e. left-hand side) validator has failed.

Let's say we have extracted some "common validations" and have some concrete validators, which utilize these reusable common validations (more or less repeating the motif of the previous example, shortening non-essential for this section parts for clarity):

```ruby
CommonValidator =
  Datacaster.partial_schema do
    hash_schema(
      description: string
    )
  end

PersonValidator =
  Datacaster.schema do
    hash_schema(
      name: string
    )
  end

RecordValidator =
  Datacaster.schema do
    CommonValidator & PersonValidator
  end
```

This code will work as expected (i.e. `RecordValidator`, the "end" validator, will check that provided hash value both has `name` and `description` string fields), except for one specific case:

```ruby
RecordValidator.(kind: 'person', name: 1)
# => Datacaster::ErrorResult({:description=>["must be string"]})
```

It correctly returns `ErrorResult`, but it doesn't mention that in addition to `description` being wrongfully absent, `name` field is of wrong type (integer instead of string). That could be inconvenient where Datacaster is used, for example, as a params validator for an API service: end user of the API would need to repeatedly send requests, essentially "brute forcing" his way in through all the errors (fixing them one by one), instead of having the list of all errors in one iteration.

Specifically to resolve this, "AND with error aggregation" (`*`) operator should be used in place of regular AND (`&`):

```ruby
RecordValidator =
  Datacaster.schema do
    CommonValidator * PersonValidator
  end

RecordValidator.(kind: 'person', name: 1)
# => Datacaster::ErrorResult({:description=>["must be string"], :name=>["must be string"]})
```

Note: "star" (`*`) has been chosen arbitrarily among available Ruby operators. It shouldn't be read as multiplication (and, in fact, in Ruby it is used not only as multiplication sign).

Described in this example is the only case where `*` and `&` differ: in all other aspects they are full equivalents.

Formally, "AND with error aggregation" (`*`):

a) if left-hand side fails, calls right-hand side anyway and then returns aggregated (merged) `ErrorResult`s,
b) in all other cases behaves as regular "AND" (`&`).

### Shortcut nested definitions

Datacaster aimed at ease of use where multi-level embedded structures need to be validated, boilerplate reduced to inevitable minimum.

The words `hash_schema` and `array_schema`/`array_of` could be, therefore, omitted from the definition of nested structures (replaced with `{...}` and `[...]` correspondingly):

```ruby
# full definition
person =
  Datacaster.schema do
    hash_schema(
      name: string,
      date_of_birth: hash_schema(
        day: integer,
        month: integer,
        year: integer
      ),
      friends: array_of(
        hash_schema(
          id: integer,
          login: string
        )
      )
    )
  end

# shortcut definition
person =
  Datacaster.schema do
    hash_schema(
      name: string,
      date_of_birth: {
        day: integer,
        month: integer,
        year: integer
      },
      friends: [
        {
          id: integer,
          login: string
        }
      ]
    )
  end
```

Note: in "root" scope (immediately inside of `schema { ... }` block) words `hash_schema` and `array_of` are still required. We consider that allowing to omit them as well would hurt readability of code.

### Mapping hashes: `transform_to_hash`

One common task in processing compound data structures is to map one set of hash keys to another set. That's where `transform_to_hash` type comes to play (see also `pluck` and `remove` description above in this file).

```ruby
city_with_distance =
  Datacaster.schema do
    transform_to_hash(
      distance_in_km: pick(:distance_in_meters) & transform { |x| x / 1000 },
      distance_in_miles: pick(:distance_in_meters) & transform { |x| x / 1000 * 1.609 },
      distance_in_meters: remove
    )
  end

city_with_distance.(distance_in_meters: 1200.0)
# => Datacaster::ValidResult({:distance_in_km=>1.2, :distance_in_miles=>1.9307999999999998})
```

Of course, order of keys in the definition hash doesn't change anything.

Formally, `transform_to_hash`:

a) transforms (any) value to hash;  
b) this hash will contain keys listed in `transform_to_hash` definition;  
c) value of these keys will be: initial value (*not the corresponding key of it, the value altogether*) transformed with the corresponding validator/type;  
d) if any of the values from c) happen to be `Datacaster.absent`, this value *with its key* is removed from the resultant hash;  
e) if the initial value happens to also be a hash, all its keys, except those which had been transformed, are merged to the resultant hash.

`transform_to_hash` will return ValidResult if and only if all transformations return ValidResults.

`transform_to_hash` will always transform the initial value.

Here is what is happening when `city_with_distance` (from the example above) is called:

* Initial hash `{distance_in_meters: 1200}` is passed to `transform_to_hash`
* `transform_to_hash` reads through its definition and creates resultant hash with the keys `distance_in_km`, `distance_in_miles`, `distance_in_meters`
* The key `distance_in_km` of the resultant hash in the transformation of the initial hash: firstly, hash is transformed to the value of its key with `pluck`, then that value is divided by 1000
* Similarly, `distance_in_miles` value is built
* `distance_in_meters` value is created by transforming initial value to `Datacaster.absent` (that is how `remove` works)

Note: because of point e) above we need to explicitly delete `distance_in_meters` key, because otherwise `transform_to_hash` will copy it to the resultant hash without validation. And all non-validated keys at the end of `Datacaster.schema` block (as explained above in section on partial schemas) result in error.

## Error remapping

In some cases it might be useful to remap resulting `Datacaster::ErrorResult`:

```ruby
schema =
  Datacaster.schema do
    transform = transform_to_hash(
      posts: pick(:user_id) & to_integer & transform { |user| Posts.where(user_id: user.id).to_a },
      user_id: remove
    )
  end

schema.(user_id: 'wrong')  # => #<Datacaster::ErrorResult({:posts=>["must be integer"]})>
# Instead of #<Datacaster::ErrorResult({:user_id=>["must be integer"]})>
```

`.cast_errors` can be used in such case:

```ruby
schema =
  Datacaster.schema do
    transform = transform_to_hash(
      posts: pick(:user_id) & to_integer & transform { |user| Posts.where(user_id: user.id).to_a },
      user_id: remove
    )

    transform.cast_errors(
      transform_to_hash(
        user_id: pick(:posts),
        posts: remove
      )
    )
  end

schema.(user_id: 'wrong')  # => #<Datacaster::ErrorResult({:user_id=>["must be integer"]})>
```
any instance of `Datacaster` can be passed to `.cast_errors`


## Registering custom 'predefined' types

In order to extend `Datacaster` functionality, custom types can be added

There are two ways to add cutsom types to `Datacaster`:

1\. Using lambda definition:

```ruby
Datacaster::Config.add_predefined_caster(:time_string, -> {
  string & validate(format: { with: /\A(0[0-9]|1[0-9]|2[0-3]):[03]0\z/ })
})

schema = Datacaster.schema { time_string }

schema.("23:00") # => #<Datacaster::ValidResult("23:00")>
schema.("no_time_string") # => #<Datacaster::ErrorResult(["is invalid"])>
```

2\. Using `Datacaster` instance:

```ruby
css_color = Datacaster.partial_schema { string & validate(format: { with: /\A#(?:\h{3}){1,2}\z/ }) }
Datacaster::Config.add_predefined_caster(:css_color, css_color)

schema = Datacaster.schema { css_color }

schema.("#123456") # => #<Datacaster::ValidResult("#123456")>
schema.("no_css_color") #  => #<Datacaster::ErrorResult(["is invalid"])>
```

## Contributing

Fork, create issues and make PRs as usual.

## Ideas/TODO

* Support pattern matching on Datacaster::Result
* Duplicate all standard ActiveModel validations as built-in datacaster counterparts

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
