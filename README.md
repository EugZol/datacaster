# Datacaster

This gem provides DSL for describing in a composable manner and performing run-time type checks and transformations of composite data structures (i.e. hashes/arrays of literals). Inspired by several concepts of functional programming such as monads.

Detailed error-reporting (with full i18n support) is one of a distinct features. Let your API consumer know precisely which fields and in a what manner are wrong in a deeply nested structure!

It is currently used in production in several projects (mainly as request parameter validator).

# Table of contents

- [Installing](#installing)
- [Why not ...](#why-not-)
- [Basics](#basics)
  - [Conveyor belt](#conveyor-belt)
  - [Result value](#result-value)
  - [Hash schema](#hash-schema)
  - [Logical operators](#logical-operators)
    - [*AND operator*](#and-operator)
    - [*OR operator*](#or-operator)
    - [*IF... THEN... ELSE operator*](#if-then-else-operator)
    - [*SWITCH... ON... ELSE operator*](#switch-on-else-operator)
- [Built-in types](#built-in-types)
  - [Basic types](#basic-types)
    - [`array(error_key = nil)`](#arrayerror_key--nil)
    - [`decimal(digits = 8, error_key = nil)`](#decimaldigits--8-error_key--nil)
    - [`float(error_key = nil)`](#floaterror_key--nil)
    - [`hash_value(error_key = nil)`](#hash_valueerror_key--nil)
    - [`integer(error_key = nil)`](#integererror_key--nil)
    - [`numeric(error_key = nil)`](#numericerror_key--nil)
    - [`string(error_key = nil)`](#stringerror_key--nil)
  - [Convenience types](#convenience-types)
    - [`hash_with_symbolized_keys(error_key = nil)`](#hash_with_symbolized_keyserror_key--nil)
    - [`integer32(error_key = nil)`](#integer32error_key--nil)
    - [`maximum(max, error_key = nil, inclusive: true)`](#maximummax-error_key--nil-inclusive-true)
    - [`minimum(min, error_key = nil, inclusive: true)`](#minimummin-error_key--nil-inclusive-true)
    - [`non_empty_string(error_key = nil)`](#non_empty_stringerror_key--nil)
    - [`pattern(regexp, error_key = nil)`](#patternregexp-error_key--nil)
    - [`uuid(error_key = nil)`](#uuiderror_key--nil)
  - [Special types](#special-types)
    - [`absent(error_key = nil, on: nil)`](#absenterror_key--nil-on-nil)
    - [`any(error_key = nil)`](#anyerror_key--nil)
    - [`attribute(*keys)`](#attributekeys)
    - [`default(default_value, on: nil)`](#defaultdefault_value-on-nil)
    - [`merge_message_keys(*keys)`](#merge_message_keyskeys)
    - [`must_be(klass, error_key = nil)`](#must_beklass-error_key--nil)
    - [`optional(base, on: nil)`](#optionalbase-on-nil)
    - [`pass`](#pass)
    - [`pass_if(base)`](#pass_ifbase)
    - [`pick(*keys)`](#pickkeys)
    - [`remove`](#remove)
    - [`responds_to(method, error_key = nil)`](#responds_tomethod-error_key--nil)
    - [`with(key, caster)`](#withkey-caster)
    - [`transform_to_value(value)`](#transform_to_valuevalue)
  - ["Web-form" types](#web-form-types)
    - [`iso8601(error_key = nil)`](#iso8601error_key--nil)
    - [`optional_param(base)`](#optional_parambase)
    - [`to_boolean(error_key = nil)`](#to_booleanerror_key--nil)
    - [`to_float(error_key = nil)`](#to_floaterror_key--nil)
    - [`to_integer(error_key = nil)`](#to_integererror_key--nil)
  - [Custom and fundamental types](#custom-and-fundamental-types)
    - [`cast { |value| ... }`](#cast--value--)
    - [`check(error_key = nil) { |value| ... }`](#checkerror_key--nil--value--)
    - [`try(error_key = nil, catched_exception:) { |value| ... }`](#tryerror_key--nil-catched_exception--value--)
    - [`validate(active_model_validations, name = 'Anonymous')`](#validateactive_model_validations-name--anonymous)
    - [`compare(reference_value, error_key = nil)`](#comparereference_value-error_key--nil)
    - [`included_in(reference_values, error_key: nil)`](#included_inreference_values-error_key-nil)
    - [`relate(left, op, right, error_key: nil)`](#relateleft-op-right-error_key-nil)
    - [`run { |value| ... }`](#run--value--)
    - [`transform { |value| ... }`](#transform--value--)
    - [`transform_if_present { |value| ... }`](#transform_if_present--value--)
  - [Array schemas](#array-schemas)
  - [Hash schemas](#hash-schemas)
    - [Absent is not nil](#absent-is-not-nil)
    - [Schema vs Partial schema vs Choosy schema](#schema-vs-partial-schema-vs-choosy-schema)
    - [AND with error aggregation (`*`)](#and-with-error-aggregation-)
  - [Shortcut nested definitions](#shortcut-nested-definitions)
  - [Mapping hashes: `transform_to_hash`](#mapping-hashes-transform_to_hash)
- [Passing additional context to schemas](#passing-additional-context-to-schemas)
- [Error remapping: `cast_errors`](#error-remapping-cast_errors)
- [Internationalization (i18n)](#internationalization-i18n)
  - [Custom absolute keys](#custom-absolute-keys)
  - [Custom relative keys and scopes](#custom-relative-keys-and-scopes)
  - [Providing interpolation variables](#providing-interpolation-variables)
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

validator.(1)             # Datacaster::ErrorResult(["is not a string"])
validator.(1).valid?      # false
validator.(1).value       # nil
validator.(1).errors      # ["is not a string"]
```

Datacaster instances are created with a call to `Datacaster.schema { ... }`, `Datacaster.partial_schema { ... }` or `Datacaster.choosy_schema { ... }`.

Datacaster validators' results could be converted to [dry result monad](https://dry-rb.org/gems/dry-monads/1.0/result/):

```ruby
require 'datacaster'

validator = Datacaster.schema { string }

validator.("test").to_dry_result # Success("test")
validator.(1).to_dry_result      # Failure(["is not a string"])
```

`string` method call inside of the block in the examples above returns (with the help of some basic meta-programming magic) 'chainable' datacaster instance. To 'chain' datacaster instances 'logical AND' (`&`) operator is used:

```ruby
require 'datacaster'

validator = Datacaster.schema { string & check { |x| x.length > 5 } }

validator.("test1") # Datacaster::ValidResult("test12")
validator.(1)       # Datacaster::ErrorResult(["is not a string"])
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

You can call `#valid?`, `#value`, `#errors` methods directly, or, if preferred, call `#to_dry_result` method to convert `Datacaster::Result` to the corresponding `Dry::Monads::Result`.

`#value` and `#errors` would return `#nil` if the result is, correspondingly, `ErrorResult` and `ValidResult`.

`#value!` would return value for `ValidResult` and raise an error for `ErrorResult`.

`#value_or(another_value)` and `#value_or { |errors| another_value }` would return value for `ValidResult` and `another_value` for `ErrorResult`.

Errors are returned as array or hash (or hash of arrays, or array of hashes, etc., for complex data structures). Errors support internationalization (i18n) natively. Each element of the returned array shows a separate error as a special i18n value object, and each key of the returned hash corresponds to the key of the validated hash. When calling `#errors` those i18n value objects are converted to strings using the configured/detected I18n backend (Rails or `ruby-i18n`).

In this README, instead of i18n values English strings are provided for brevity:

```ruby
array = Datacaster.schema { array }
array.(nil)

# In this README
# => Datacaster::ErrorResult(['should be an array'])

# In reality
# => <Datacaster::ErrorResult([#<Datacaster::I18nValues::Key(.array, datacaster.errors.array) {:value=>nil}>])>
```

See [section on i18n](#internationalization-i18n) for details.

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
# => Datacaster::ErrorResult({:salary=>["is not an integer"]})

person_validator.("test")
# => Datacaster::ErrorResult(["is not a hash"])

person_validator.(name: "John Smith", salary: "1000")
# => Datacaster::ErrorResult({:salary=>["is not an integer"]})

person_validator.(name: :john, salary: "1000")
# => Datacaster::ErrorResult({:name=>["is not a string"], :salary=>["is not an integer"]})

person_validator.(name: "John Smith", salary: 100_000, title: "developer")
# => Datacaster::ErrorResult({:title=>["should be absent"]})
```

`Datacaster.schema` definitions don't permit, as you have likely noticed from the example above, extra fields in the hash.

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

#### *AND operator*

```ruby
even_number = Datacaster.schema { integer & check { |x| x.even? } }

even_number.(2)
# => Datacaster::ValidResult(2)

even_number.(3)
# => Datacaster::ErrorResult(["is invalid"])
even_number.("test")
# => Datacaster::ErrorResult(["is not an integer"])
```

If left-hand validation of AND operator passes, *its result* (not the original value) is passed to the right-hand validation.

Alternatively, `steps` caster could be used, which accepts any number of "steps" as arguments and joins them with `&` logic:

```ruby
even_number =
  Datacaster.schema do
    steps(
      integer,
      check { |x| x.even? },
      transform { |x| x * 2 }
    )
  end

even_number.(6)
# => Datacaster::ValidResult(12)
```

Naturally, if one of the "steps" returns an error, process short-circuits and this error is returned as a result.

#### *OR operator*

```ruby
# 'compare' custom type returns ValidResult if and only if validated value == compare's argument
person_or_entity = Datacaster.schema { compare(:person) | compare(:entity) }

person_or_entity.(:person) # => Datacaster::ValidResult(:person)
person_or_entity.(:entity) # => Datacaster::ValidResult(:entity)

person_or_entity.(:ngo)    # => Datacaster::ErrorResult(["does not equal :entity"])
```

Notice that OR operator, if left-hand validation fails, passes the original value to the right-hand validation. As you see in the example above resultant error messages are not always convenient (i.e. to show something like "value must be :person or :entity" is preferable to showing somewhat misleading "must be equal to :entity"). See the next section on "IF... THEN... ELSE" for closer to the real world example.

#### *IF... THEN... ELSE operator*

Let's support we want to run different validations depending on some value, e.g.:

* if 'salary' is more than 100_000, check for the additional key, 'passport'
* otherwise, ensure 'passport' key is absent
* in any case, check that 'name' key is present and is a string

```ruby
applicant =
  Datacaster.schema do
    base = hash_schema(
      name: string,
      salary: integer
    )

    large_salary = check { |x| x[:salary] > 100_000 }

    base &
      large_salary.
        then(passport: string).
        else(passport: absent)
  end

applicant.(name: 'John', salary: 50_000)
# => Datacaster::ValidResult({:name=>"John", :salary=>50000})

applicant.(name: 'Jane', salary: 101_000, passport: 'AB123CD')
# => Datacaster::ValidResult({:name=>"Jane", :salary=>101000, :passport=>"AB123CD"})

applicant.(name: 'George', salary: 101_000)
# => Datacaster::ErrorResult({:passport=>["is not a string"])
```

Formally, with `a.then(b).else(c)`:

* if `a` returns `ValidResult`, then `b` is called *with the result of `a`* (not the original value) and whatever `b` returns is returned;
* otherwise, `c` is called with the original value, and whatever `c` returns is returned.

`else`-part is required and could not be omitted.

Note: this construct is *not* an equivalent of `a & b | c`.

With `a.then(b).else(c)` if `a` and `b` fails, then `b`'s error is returned. With `a & b | c`, instead, `c`'s result would be returned.

#### *SWITCH... ON... ELSE operator*

Let's suppose we want to validate that incoming hash is either 'person' or 'entity', where:

* 'person' is a hash with 3 keys (kind: `:person`, name: string, salary: integer),
* 'entity' is a hash with 4 keys (kind: `:entity`, title: string, form: string, revenue: integer).

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


    # 1. First option, explicit definition

    kind_is_valid &
      switch(pick(:kind)).
        on(compare(:person), person).
        on(compare(:entity), entity)

    # 2. Second option, shortcut definiton

    kind_is_valid &
      switch(:kind).
        on(:person, person).
        on(:entity, entity)

    # 3. Third option, using keywords args and Ruby 3.1 value omission in hash literals

    kind_is_valid &
      switch(:kind, person:, entity:)
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

In our opinion the above example shows most laconic way to express underlying 'business-logic' (including elaborate error reporting on all kinds of failures) among all available competitor approaches/gems.

Notice that shortcut definitions are available (illustrated in the example above) for the switch caster:

* `switch(:key)` is exactly the same as `switch(pick(:key))` (works for a string, a symbol, or an array thereof)
* `on(:key, ...)` is exactly the same as `on(compare(:key), ...)` (works for a string or a symbol)
* `on(:key, ...)` will match on `:key` and `'key'` value, and the same is true for `on('key', ...)` (to disable that behavior provide `strict: true` keyword arg: `on('key', ..., strict: true)`)
* `switch([caster], on_check => on_caster, ...)` is exactly the same as `switch([caster]).on(on_check, on_caster).on(...)`

`switch()` without a `base` argument will pass the incoming value to the `.on(...)` casters.

Formally, with `switch(a).on(on_check, on_caster).else(c)`:

* if `a` returns ErrorResult, it is the result of the switch
* otherwise, all `on_check` casters from the `.on` blocks are called with the result of `a`, until the first one which returns ValidResult is found – corresponding `on_caster` is called with the original value and its result is the result of the switch
* if all `on_check`-s returned ErrorResult
  * and there is an `.else` block, `c` is called with the original value and its result is the result of the switch
  * if there is no `.else` block, `ErrorResult(['is invalid'])` is returned from the switch

I18n keys:

* all `.on` checks resulted in an error and there is no `.else`: `'.switch'`, `'datacaster.errors.switch'`

## Built-in types

Full description of all built-in types follows.

Under "I18n keys" error keys (in the order of priority) which caster will use for translation of error messages are provided. Each caster provides `value` variable for i18n interpolation, setting it to `#to_s` of incoming value. Some casters provide additional variables, which is mentioned in the same section. See [Internationalization (i18n)](#internationalization-i18n) for the details.

### Basic types

#### `array(error_key = nil)`

Returns ValidResult if and only if provided value is an `Array`. Doesn't transform the value.

I18n keys: `error_key`, `'.array'`, `'datacaster.errors.array'`.

#### `decimal(digits = 8, error_key = nil)`

Returns ValidResult if and only if provided value is either a float, integer or string representing float/integer.

Transforms the value to the `BigDecimal` instance.

I18n keys: `error_key`, `'.decimal'`, `'datacaster.errors.decimal'`.

#### `float(error_key = nil)`

Returns ValidResult if and only if provided value is a float (checked with Ruby's `#is_a?(Float)`, i.e. integers are not considered valid floats). Doesn't transform the value.

I18n keys: `error_key`, `'.float'`, `'datacaster.errors.float'`.

#### `hash_value(error_key = nil)`

Returns ValidResult if and only if provided value is a `Hash`. Doesn't transform the value.

Note: this type is called `hash_value` instead of `hash`, because `hash` is a reserved method name in Ruby.

I18n keys: `error_key`, `'.hash_value'`, `'datacaster.errors.hash_value'`.

#### `integer(error_key = nil)`

Returns ValidResult if and only if provided value is an integer. Doesn't transform the value.

I18n keys: `error_key`, `'.integer'`, `'datacaster.errors.integer'`.

#### `numeric(error_key = nil)`

Returns ValidResult if and only if provided value is a number (Ruby's `Numeric`). Doesn't transform the value.

I18n keys: `error_key`, `'.numeric'`, `'datacaster.errors.numeric'`.

#### `string(error_key = nil)`

Returns ValidResult if and only if provided value is a string. Doesn't transform the value.

I18n keys: `error_key`, `'.string'`, `'datacaster.errors.string'`.

### Convenience types

#### `hash_with_symbolized_keys(error_key = nil)`

Returns ValidResult if and only if provided value is an instance of `Hash`. Transforms the value to `#hash_with_symbolized_keys` (requires `ActiveSupport`).

I18n keys: `error_key`, `'.hash_value'`, `'datacaster.errors.hash_value'`.

#### `integer32(error_key = nil)`

Returns ValidResult if and only if provided value is an integer and it's absolute value is <= 2_147_483_647. Doesn't transform the value.

I18n keys:

* not an integer – `error_key`, `'.integer'`, `'datacaster.errors.integer'`
* too big – `error_key`, `'.integer32'`, `'datacaster.errors.integer32'`

#### `maximum(max, error_key = nil, inclusive: true)`

Returns ValidResult if and only if provided value is a number and is less than `max`. If `inclusive` set to true, provided value should be less than or equal to `max`. Doesn't transform the value.

I18n keys:

* not a number – `error_key`, `'.numeric'`, `'datacaster.errors.numeric'`
* is less (when `inclusive` is `true`) – `error_key`, `'.maximum.lteq'`, `'datacaster.errors.maximum.lteq'`
* is less (when `inclusive` is `false`) – `error_key`, `'.maximum.lt'`, `'datacaster.errors.maximum.lt'`

#### `minimum(min, error_key = nil, inclusive: true)`

Returns ValidResult if and only if provided value is a number and is greater than `min`. If `inclusive` set to true, provided value should be greater than or equal to `min`. Doesn't transform the value.

I18n keys:

* not a number – `error_key`, `'.numeric'`, `'datacaster.errors.numeric'`
* is greater (when `inclusive` is `true`) – `error_key`, `'.minimum.gteq'`, `'datacaster.errors.minimum.gteq'`
* is greater (when `inclusive` is `false`) – `error_key`, `'.minimum.gt'`, `'datacaster.errors.minimum.gt'`

#### `non_empty_string(error_key = nil)`

Returns ValidResult if and only if provided value is a string and is not empty. Doesn't transform the value.

I18n keys:

* not a string – `error_key`, `'.string'`, `'datacaster.errors.string'`
* is empty – `error_key`, `'.non_empty_string'`, `'datacaster.errors.non_empty_string'`

#### `pattern(regexp, error_key = nil)`

Returns ValidResult if and only if provided value is a string and satisfies regexp. Doesn't transform the value. Don't forget to provide start/end markers in the regexp if needed, e.g. `/\A\d+\z/` for digits-only string.

I18n keys:

* not a string – `error_key`, `'.string'`, `'datacaster.errors.string'`
* doesn't satisfy the regexp – `error_key`, `'.pattern'`, `'datacaster.errors.pattern'`

#### `uuid(error_key = nil)`

Returns ValidResult if and only if provided value is a string and UUID. Doesn't transform the value.

I18n keys:

* not a string – `error_key`, `'.string'`, `'datacaster.errors.string'`
* not UUID – `error_key`, `'.uuid'`, `'datacaster.errors.uuid'`

### Special types

#### `absent(error_key = nil, on: nil)`

Returns ValidResult if and only if provided value is absent. Relevant only for hash schemas (see below). Transforms the value to `Datacaster.absent`.

The value is considered absent:

* if the value is `Datacaster.absent` (`on` is disregarded in such case)
* if `on` is set to a method name to which the value responds and yields truthy

Set `on` to `:nil?`, `:empty?` or similar method names.

I18n keys: `error_key`, `'.absent'`, `'datacaster.errors.absent'`.

#### `any(error_key = nil)`

Returns ValidResult if and only if provided value is not `Datacaster.absent` (this is singleton instance). Relevant only for hash schemas (see below). Doesn't transform the value.

I18n keys: `error_key`, `'.any'`, `'datacaster.errors.any'`

#### `attribute(*keys)`

Always returns ValidResult. Calls provided method(s) (recursively) on the value and returns their results. `*keys` should be specified in exactly the same manner as in [pick](#pickkeys).

```ruby
class User
  def login
    "Alex"
  end
end

login = Datacaster.schema { attribute(:login) }

# => Datacaster::ValidResult("Alex")
login.(User.new)

# => Datacaster::ValidResult(#<Datacaster.absent>)
login.("test")
```

#### `default(default_value, on: nil)`

Always returns ValidResult.

Returned `default_value` is deeply frozen with [Ractor::make_shareable](https://docs.ruby-lang.org/en/master/Ractor.html#method-c-make_shareable) to prevent application bugs due to modification of unintentionally shared value. If that effect is undesired, use [`transform { value }`](#transform--value--) instead.

Returns `default_value` in the following cases:

* if the value is `Datacaster.absent` (`on` is disregarded in such case)
* if `on` is set to a method name to which the value responds and yields truthy

Returns the initial value otherwise.

Set `on` to `:nil?`, `:empty?` or similar method names.

#### `merge_message_keys(*keys)`

Returns ValidResult only if the value `#is_a?(Hash)`.

Picks given keys of incoming hash and merges their values recursively.

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

Hash keys with `nil` and `[]` values are removed recursively:

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

See also `#cast_errors` for [error remapping](#error-remapping-cast_errors).

See also `#pick` for [simpler picking of hash values](#pickkeys).

I18n keys:

* not a hash – `'.hash_value'`, `'datacaster.errors.hash_value'`

#### `must_be(klass, error_key = nil)`

Returns ValidResult if and only if the value `#is_a?(klass)`. Doesn't transform the value.

I18n keys: `error_key`,  `'.must_be'`, `'datacaster.errors.must_be'`. Adds `reference` i18n variable, setting it to `klass.name`. 

#### `optional(base, on: nil)`

Returns ValidResult if and only if the value is either absent or passes `base` validation. In the value is absent, transforms it to the `Datacaster.absent`. Otherwise, returns `base` result.

Value is considered absent:

* if the value is `Datacaster.absent` (`on` is disregarded in such case)
* if `on` is set to a method name to which the value responds and yields truthy

Set `on` to `:nil?`, `:empty?` or similar method names.

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
# => Datacaster::ErrorResult({:price=>["is not a float"]})
```

#### `pass`

Always returns ValidResult. Doesn't transform the value.

Useful to "mark" the value as validated (see section below on hash schemas, where this could be applied).

#### `pass_if(base)`

Returns ValidResult if and only if base returns ValidResult. Returns base's error result otherwise.

Doesn't transform the value: if base succeeds returns the original value (not the one that base returned).

#### `pick(*keys)`

Returns ValidResult if and only if the value `#is_a?(Enumerable)`.

Each argument should be a string, a Symbol, an integer or an array thereof. Each argument plays the role of key(s) to fetch from the value:

* If the argument is an Array, value is extracted recursively
* Otherwise, `value[argument]` is fetched and added to the result (or `Datacaster.absent` if is is impossible to fetch)

If only one argument is provided to the `pick`, one fetched value is returned. If several arguments are provided, array is returned wherein each value corresponds to each argument.

Fetching single key:

```ruby
pick_name = Datacaster.schema { pick(:name) }

pick_name.(name: "George")       # => Datacaster::ValidResult("George")
pick_name.(last_name: "Johnson") # => Datacaster::ValidResult(#<Datacaster.absent>)

pick_name.("test")               # => Datacaster::ErrorResult(["is not Enumerable"])
```

Fetching multiple keys:

```ruby
pick_name_and_age = Datacaster.schema { pick(:name, :age) }

pick_name_and_age.(name: "George", age: 20)       # => Datacaster::ValidResult(["George", 20])
pick_name_and_age.(last_name: "Johnson", age: 20) # => Datacaster::ValidResult([#<Datacaster.absent>, 20])

pick_name_and_age.("test")                        # => Datacaster::ErrorResult(["is not Enumerable"])
```

Fetching deeply nested key:

```ruby
nested_hash_picker = Datacaster.schema { pick([:user, :age]) }

nested_hash_picker.(user: { age: 21 })      # => Datacaster::ValidResult(21)
nested_hash_picker.(user: { name: "Alex" }) # => Datacaster::ValidResult(#<Datacaster.absent>)
```

I18n keys:

* not a Enumerable – `'.must_be'`, `'datacaster.errors.must_be'`.

#### `remove`

Always returns ValidResult. Always returns `Datacaster.absent`.

#### `responds_to(method, error_key = nil)`

Returns ValidResult if and only if the value `#responds_to?(method)`. Doesn't transform the value.

I18n keys: `error_key`, `'.responds_to'`, `'datacaster.errors.responds_to'`. Adds `reference` i18n variable, setting it to `method.to_s`.

#### `with(key, caster)`

Returns ValidResult if and only if value is enumerable and `caster` returns ValidResult. Transforms incoming hash, providing value described by `key` to `caster`, and putting its result back into the original hash.

```ruby
upcase_name =
  Datacaster.schema do
    with(:name, transform(&:upcase))
  end

upcase_name.(name: 'Josh')
# => Datacaster::ValidResult({:name=>"JOSH"})
```

If an array is provided instead of string or Symbol for `key` argument, it is treated as array of key names for a deeply nested value:

```ruby
upcase_person_name =
  Datacaster.schema do
    with([:person, :name], transform(&:upcase))
  end

upcase_person_name.(person: {name: 'Josh'})
# => Datacaster::ValidResult({:person=>{:name=>"JOSH"}})

upcase_person_name.({})
# => Datacaster::ErrorResult({:person=>["is not Enumerable"]})
```

Note that `Datacaster.absent` will be provided to `caster` if corresponding key is absent from the value.

I18n keys:

* is not enumerable – `'.must_be'`, `'datacaster.errors.must_be'`. Adds `reference` i18n variable, setting it to `"Enumerable"`.

#### `transform_to_value(value)`

Always returns ValidResult. The value is transformed to provided argument (disregarding the original value). If the resultant value is a Hash, all its keys are marked as validated and will survive `Datacaster.schema { ... }` call.

Returned value is deeply frozen with [`Ractor::make_shareable`](https://docs.ruby-lang.org/en/master/Ractor.html#method-c-make_shareable) to prevent application bugs due to modification of unintentionally shared value. If that effect is undesired, use [`transform { value }`](#transform--value--) instead.

See also [`default`](#defaultdefault_value-on-nil).

### "Web-form" types

These types are convenient to parse and validate POST forms and decode JSON requests.

#### `iso8601(error_key = nil)`

Returns ValidResult if and only if the value is a string in [ISO8601](https://en.wikipedia.org/wiki/ISO_8601) date-time format.

```ruby
dob = Datacaster.schema { iso8601 }

dob.("2011-02-03")
# => Datacaster::ValidResult(#<DateTime: 2011-02-03T00:00:00+00:00 ...>)
```

Transforms the value to the `DateTime` instance.

I18n keys: `error_key`, `'.iso8601'`, `'datacaster.errors.iso8601'`.

#### `optional_param(base)`

Returns ValidResult if and only if the value is absent, empty string or passes `base` validation.

If the value is empty string (`""`), transforms it to `Datacaster.absent` instance. It makes sense to use this type in conjunction with hash schema validations (see below), where `Datacaster.absent` keys are removed from the resultant hash.

Otherwise, doesn't transform the value.

#### `to_boolean(error_key = nil)`

Returns ValidResult if and only if the value is `true`, `1`, `'true'` or `false`, `0`, `'false'`. Transforms the value to `true` or `false` (using apparent convention).

I18n keys: `error_key`, `'.to_boolean'`, `'datacaster.errors.to_boolean'`

#### `to_float(error_key = nil)`

Returns ValidResult if and only if the value is an integer, float or string representing integer/float. Transforms value to float.

I18n keys: `error_key`, `'.to_float'`, `'datacaster.errors.to_float'`

#### `to_integer(error_key = nil)`

Returns ValidResult if and only if the value is an integer, float or string representing integer/float. Transforms the value to the integer.

I18n keys: `error_key`, `'.to_integer'`, `'datacaster.errors.to_integer'`.

### Custom and fundamental types

These types are used to create 'hand-crafted' validators.

#### `cast { |value| ... }`

The most basic &mdash; "fully manual" &mdash; validator.

Calls the block with the value. Returns whatever the block returns.

Provided block must return either a `Datacaster::Result` or a `Dry::Result::Monad` (the latter will automatically be converted to the former), otherwise `cast` will raise a runtime error.

```ruby
# Actually, it's better to use 'check' here instead
user_id_exists =
  Datacaster.schema do
    cast do |user_id|
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

Notice, that for this example (as is written in the comment) `check` type is a better option (see below).

`cast` will transform the value, if such is the logic of the provided block.

#### `check(error_key = nil) { |value| ... }`

Returns ValidResult if and only if the provided block returns truthy value.

```ruby
user_id_exists =
  Datacaster.schema do
    check do |user_id|
      User.exists?(user_id)
    end
  end
```

Doesn't transform the value.

I18n keys: `error_key`, `'.check'`, `'datacaster.errors.check'`.

#### `try(error_key = nil, catched_exception:) { |value| ... }`

Returns ValidResult if and only if the block finishes without exceptions. If the block raises an exception:

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

Doesn't transform the value.

I18n keys: `error_key`, `'.try'`, `'datacaster.errors.try'`

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

I18n is performed by ActiveModel gem.

#### `compare(reference_value, error_key = nil)`

Returns ValidResult if and only if `reference_value` equals value.

```ruby
agreed_with_tos =
  Datacaster.partial_schema do
    hash_schema(
      agreed: compare(true)
    )
  end
```

I18n keys: `error_key`, `'.compare'`, `'datacaster.errors.compare'`. Adds `reference` i18n variable, setting it to `reference_value.to_s`.

#### `included_in(reference_values, error_key: nil)`

Returns ValidResult if and only if `reference_values.include?` the value.

I18n keys: `error_key`, `'.included_in'`, `'datacaster.errors.included_in'`. Adds `reference` i18n variable, setting it to `reference_values.map(&:to_s).join(', ')`.

#### `relate(left, op, right, error_key: nil)`

Returns ValidResult if and only if `left`, `right` and `op` returns valid result. Doesn't transform the value.

Use `relate` to check relations between object keys:

```ruby
ordered =
  # Check that hash[:a] < hash[:b]
  Datacaster.schema do
    transform_to_hash(
      a: relate(:a, :<, :b) & pick(:a),
      b: pick(:b)
    )
  end

ordered.(a: 1, b: 2)
# => Datacaster::ValidResult({:a=>1, :b=>2})

ordered.(a: 2, b: 1)
# => Datacaster::ErrorResult({:a=>["a should be < b"]})

ordered.({})
# => Datacaster::ErrorResult({:a=>["a should be < b"]})
```

Notice that shortcut definitions are available (illustrated in the example above) for the `relate` caster:

* `:key` provided as 'left' or 'right' argument is exactly the same as `pick(:key)` (works for a string, a symbol or an integer)
* `:method` provided as 'op' argument is exactly the same as `check { |(l, r)| l.respond_to?(method) && l.public_send(method, r) }` (works for a string or a symbol)

Formally, `relate(left, op, right, error_key: error_key)` will:

* call the `left` caster with the original value, return the result unless it's valid
* call the `right` caster with the original value, return the result unless it's valid
* call the `op` caster with the `[left_result, right_result]`, return the result unless it's valid
* return the original value as valid result

#### `run { |value| ... }`

Always returns ValidResult. Doesn't transform the value.

Useful to perform some side-effect such as raising an exception, making a log entry, etc.

#### `transform { |value| ... }`

Always returns ValidResult. Transforms the value: returns whatever the block has returned.

If the resultant value is a Hash, all its keys are marked as validated and will survive `Datacaster.schema { ... }` call.

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

#### `transform_if_present { |value| ... }`

Always returns ValidResult. If the value is `Datacaster.absent`, then `Datacaster.absent` is returned (the block isn't called). Otherwise, works like [`transform`](#transform--value).

If the resultant value is a Hash, all its keys are marked as validated and will survive `Datacaster.schema { ... }` call.

### Array schemas

To define compound data type, array of 'something', use `array_schema(something)` (or the alias `array_of(something)`). There is no built-in way to define an array wherein each element is of a different type.

```ruby
salaries = Datacaster.schema { array_of(integer) }

salaries.([1000, 2000, 3000]) # Datacaster::ValidResult([1000, 2000, 3000])

salaries.(["one thousand"])   # Datacaster::ErrorResult({0=>["is not an integer"]})
salaries.(:not_an_array)      # Datacaster::ErrorResult(["should be an array"])
salaries.([])                 # Datacaster::ErrorResult(["should not be empty"])
```

To allow empty array use the following construct: `compare([]) | array_of(...)`.

If you want to define an array of hashes, [shortcut definition](#shortcut-nested-definitions) could be used: instead of `array_of(hash_schema({...}))` use `array_of({...})`:

```ruby
people =
  Datacaster.schema do
    array_of(
      name: string,
      salary: float
    )
  end

person1 = {name: "John Smith", salary: 250_000.0}
person2 = {name: "George Johnson", salary: 50_000.0}
people.([person1, person2]) # => Datacaster::ValidResult([{...}, {...}])

people.([{salary: 250_000.0}, {salary: "50000"}])
# => Datacaster::ErrorResult({
#   0 => {:name => ["is not a string"]},
#   1 => {:name => ["is not a string"], :salary => ["is not a float"]}
# })
```

Notice that extra keys of inner hashes could be validated only if each element is otherwise valid. In other words, if some of the elements have other validation errors, then "extra key must be absent" validation error won't appear on any element. This could be avoided by using nested `Datacaster.schema` call to define element schema instead of shortcut definition or `hash_schema` call.

Formally, `array_of(x, error_keys = {})` will return ValidResult if and only if:

a) provided value implements basic array methods (`#map`, `#zip`),  
b) provided value is not `#empty?`,  
c) each element of the provided value passes validation of `x`.

If a) fails, `ErrorResult(["should be an array"]) is returned. 
If b) fails, `ErrorResult(["should not be empty"])` is returned.  
If c) fails, `ErrorResult({0 => ..., 1 => ...})` is returned. Wrapped hash contains keys which correspond to initial array's indices, and values correspond to failure returned from `x` validator, called for the corresponding element.

Array schema transforms array if inner type (`x`) transforms element (in this case `array_schema` works more or less like `map` function). Otherwise, it doesn't transform.

I18n keys:

* not an array – `error_keys[:array]`, `'.array'`, `'datacaster.errors.array'`
* empty array – `error_keys[:empty]`, `'.empty'`, `'datacaster.errors.empty'`

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
# => Datacaster::ErrorResult({:salary=>["is not an integer"]})
```

Formally, hash schema returns ValidResult if and only if:

a) provided value `is_a?(Hash)`,  
b) all values, fetched by keys mentioned in `hash_schema(...)` definition, pass corresponding validations,  
c) after all checks (including logical operators), there are no unchecked keys in the hash.

If a) fails, `ErrorResult(["is not a hash"])` is returned.  
if b) fails, `ErrorResult(key1 => [errors...], key2 => [errors...])` is returned. Each key of wrapped "error hash" corresponds to the key of validated hash, and each value of "error hash" contains array of errors, returned by the corresponding validator.  
If b) is fulfilled, then and only then validated hash is checked for extra keys. If they are found, `ErrorResult(extra_key_1 => ["should be absent"], ...)` is returned.

I18n keys:

* not a hash – `error_key`, `'.hash_value'`, `'datacaster.errors.hash_value'`

#### Absent is not nil

In practical tasks it's important to distinguish between absent (i.e. not set or deleted) and `nil` values of a hash.

To check some value for `nil`, use [`compare(nil)`](#comparereference_value-error_key--nil).

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
# => Datacaster::ErrorResult({:is_admin=>["should be absent"]})
restricted_params.(username: "test", is_admin: nil)
# => Datacaster::ErrorResult({:is_admin=>["should be absent"]})
```

More practical case is to include `absent` validator in logical expressions, e.g. `something: absent | string`. If `something` is set to `nil`, this validation will fail, which could be the desired (and hardly achieved by any other validation framework) behavior.

Also, see documentation for [`optional(base)`](#optionalbase-on-nil) and [`optional_param(base)`](#optional_parambase). If some value becomes `Datacaster.absent` in its chain of validations-transformations, it is removed from the resultant hash (on the same stage where the lack of extra/unchecked keys in the hash is validated):

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
# => Datacaster::ErrorResult({:dob=>["is not a string with ISO-8601 date and time"]})
```

Another use case for `Datacaster.absent` is to directly set some key to that value. In that case, it will be removed from the resultant hash. The most convenient way to do that is to use the [`remove`](#remove) cast:

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

Note: we need to `pass` `dob` field to "mark" it as validated, otherwise `Datacaster.schema` will return `ErrorResult`, notifying that unchecked extra field was in the initial hash.

#### Schema vs Partial schema vs Choosy schema

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

See also ["IF... THEN... ELSE"](#if-then-else-operator) section.

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
# => Datacaster::ErrorResult({:extra=>["should be absent"]})
```

Notice that only the usage of `Datacaster.partial_schema` instead of `Datacaster.schema` allowed us to compose several `hash_schema`s from different files (from different calls to Datacaster API).

Had we used `schema` everywhere, `CommonFieldsValidator` would return failure for records which are supposed to be valid, because they would contain "extra" (i.e. not defined in `CommonFieldsValidator` itself) keys (e.g. `name` for person).

As a rule of thumb, use `partial_schema` in any "intermediary" validators (extracted for the sake of clarity of code and reusability) and use `schema` in any "end" validators (ones which receive full record as input and use intermediary validators behind the scenes).

Lastly, if you want to just delete extra unvalidated keys without returning a error, use `choosy_schema`.

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
  Datacaster.partial_schema do
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
# => Datacaster::ErrorResult({:description=>["is not a string"]})
```

It correctly returns `ErrorResult`, but it doesn't mention that in addition to `description` being wrongfully absent, `name` field is of the wrong type (integer instead of string). Such error reporting would be incomplete.

Specifically to resolve this, "AND with error aggregation" (`*`) operator should be used in place of regular AND (`&`):

```ruby
RecordValidator =
  Datacaster.schema do
    CommonValidator * PersonValidator
  end

RecordValidator.(kind: 'person', name: 1)
# => Datacaster::ErrorResult({:description=>["is not a string"], :name=>["is not a string"]})
```

Note: "star" (`*`) has been chosen arbitrarily among available Ruby operators. It shouldn't be read as multiplication (and, in fact, in Ruby it is used not only as multiplication sign).

Described in this example is the only case where `*` and `&` differ: in all other aspects they are fully equivalent.

Formally, "AND with error aggregation" (`*`):

a) if left-hand side fails, calls right-hand side anyway and then returns aggregated (merged) `ErrorResult`s,
b) in all other cases behaves as regular "AND" (`&`).

### Shortcut nested definitions

Datacaster aimed at thr ease of use where multi-level embedded structures need to be validated, boilerplate reduced to inevitable minimum.

The words `hash_schema` and `array_schema`/`array_of` could be omitted from the definition of nested structures (replaced with `{...}` and `[...]`):

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

Note: in the "root" scope (immediately inside of `schema { ... }` block) the words `hash_schema` and `array_of` are still required. We consider that allowing to omit them as well would hurt readability of the code.

### Mapping hashes: `transform_to_hash`

One common task in processing compound data structures is to map one set of hash keys to another set. That's where `transform_to_hash` type comes to play (see also [`pick`](#pickkeys) and [`remove`](#remove)).

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

Of course, order of keys in the definition hash doesn't change the result.

Formally, `transform_to_hash`:

a) transforms (any) value to hash;  
b) this hash will contain keys listed in `transform_to_hash` definition;  
c) value of these keys will be: initial value (*not the corresponding key of it, the value altogether*) transformed with the corresponding validator/type;  
d) if any of the values from c) happen to be `Datacaster.absent`, this value *with its key* is removed from the resultant hash;  
e) if the initial value happens to also be a hash, all its unvalidated (unused) keys are merged to the resultant hash.

`transform_to_hash` will return ValidResult if and only if all transformations return ValidResults.

`transform_to_hash` will always transform the initial value.

Here is what is happening when `city_with_distance` (from the example above) is called:

* Initial hash `{distance_in_meters: 1200}` is passed to `transform_to_hash`
* `transform_to_hash` reads through its definition and creates resultant hash with the keys `distance_in_km`, `distance_in_miles`, `distance_in_meters`
* The key `distance_in_km` of the resultant hash is the transformation of the initial hash: firstly, hash is transformed to the value of its key with `pick`, then that value is divided by 1000
* Similarly, `distance_in_miles` value is built
* `distance_in_meters` value is created by transforming initial value to `Datacaster.absent` (that is how `remove` works)

Note: because of point e) above we need to explicitly delete `distance_in_meters` key, because otherwise `transform_to_hash` will copy it to the resultant hash without validation. And exitence of non-validated keys at the end of `Datacaster.schema` block results in an error result.

##  Passing additional context to schemas

It is often useful to extract common data which is used in validations, but not a main subject of validations, to a separate context object.

This can be achived by using `#with_context`, which makes provided context available in the `context` structure:

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

`context` behaves similarly to OpenStruct, setter method can be used to set a context value (see also [run](#run--value--) caster):

```ruby
schema =
  Datacaster.schema do
    run { context.five = 5 } & check { context.five == 5 }
  end

# Notice that #with_context call is still required, otherwise
# #context method will not be available in the caster's runtime
schema.with_context.(nil)
# => Datacaster::ValidResult(nil)
```

If there are conflicts between context values, the most specific one (closest to the caster) wins:

```ruby
schema =
  Datacaster.schema do
    check { context.five == 5 }.
      with_context(five: 5). # this will win
      with_context(five: 10)
  end

schema.with_context(five: 15).(nil)
# => Datacaster::ValidResult(nil)
```

Method `has_key?` could be used to determine whether key is available in the context

```ruby
schema =
  Datacaster.schema do
    check { context.has_key?(:five) }
  end

schema.with_context(five: 15).(nil)
# => Datacaster::ValidResult(nil)
```

**Note**

`context` can be accesed only in casters' blocks. It can't be used in schema definition itself:

```ruby
# will raise NoMethodError
Datacaster.schema { context.error }
```

## Error remapping: `cast_errors`

Validation often includes [remapping](#mapping-hashes-transform_to_hash) of hash keys. In such cases errors require remapping back to the original keys.

Let's see an example:

```ruby
schema =
  Datacaster.schema do
    transform = transform_to_hash(
      posts: pick(:user_id) & to_integer & transform { |user| Posts.where(user_id: user.id).to_a },
      user_id: remove
    )
  end

schema.(user_id: 'wrong')  # => #<Datacaster::ErrorResult({:posts=>["is not an integer"]})>
# Instead of #<Datacaster::ErrorResult({:user_id=>["is not an integer"]})>
```

`.cast_errors` can be used to remap errors back:

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

schema.(user_id: 'wrong')  # => #<Datacaster::ErrorResult({:user_id=>["is not an integer"]})>
```

`.cast_errors` will extract errors from the `ErrorResult` and provide them as value for the provided caster. If that caster returns `ErrorResult`, runtime exception is raised. If that caster returns `ValidResult`, it is packed back into `ErrorResult` and returned.

Any instance of `Datacaster` supports `#cast_errors`.

See also [merge_message_keys](#merge_message_keyskeys) caster.

## Internationalization (i18n)

Datacaster natively supports i18n. Default messages (their keys are listed under "I18n keys" in the caster descriptions) are packed with the gem: [`en.yml`](config/locales/en.yml).

There are several ways to customize messages, described in this section.

### Custom absolute keys

There are two ways to set absolute error key (i.e. key with full path to an error inside of a yml i18n file).

Let's consider the following i18n file:

```yml
en:
  user:
    errors:
      not_found: User %{value} has not been found
```

Interpolated i18n variable `value` is added automatically for all built-in casters.

Firstly, you can set `error_key` of a caster:

```ruby
schema = Datacaster.schema { check('user.errors.not_found') { false } }
schema.('john').errors # ['User john has not been found']
```

Secondly, you can call `#i18n_key` on a caster:

```ruby
schema =
  Datacaster.schema do
    check { false }.i18n_key('user.errors.not_found')
  end

schema.('john').errors # ['User john has not been found']
```

### Custom relative keys and scopes

More often it is required to set specific i18n namespace for the whole validation schema. There is a manual way to do it with `#i18n_scope` and automatic scoping for hashes.

Let's consider the following i18n file:

```yml
en:
  user:
    errors:
      not_found: User has not been found
    name:
      wrong_format: wrong format
```

Let's gradually reduce the boilerplate, starting with the most explicit example. Notice that all relative keys (i.e. keys which will be scoped during the execution) start with `'.'`:

```ruby
schema =
  Datacaster.schema(i18n_scope: 'user') do
    check { |v| v[:id] == 1 }.i18n_key('.errors.not_found') &
      hash_schema(
        name: check { false }.i18n_key('.name.wrong_format')
      )
  end

schema.({id: 3}).errors # ['User has not been found']
schema.({id: 1, name: 'wrong'}).errors # {name: ['wrong format']}
```

To reduce the boilerplate, Datacaster will infer scopes from hash key names:

```ruby
schema =
  Datacaster.schema(i18n_scope: 'user') do
    check { |v| v[:id] == 1 }.i18n_key('.errors.not_found') &
      hash_schema(
        # '.wrong_format' inferred to be '.name.wrong_format'
        name: check { false }.i18n_key('.wrong_format')
      )
  end

schema.({id: 1, name: 'wrong'}).errors # {name: ['wrong format']}
```

Relative keys can be set as `error_key` argument of casters:

```ruby
schema =
  Datacaster.schema(i18n_scope: 'user') do
    check('.errors.not_found') { |v| v[:id] == 1 } &
      hash_schema(
        # '.wrong_format' inferred to be '.name.wrong_format'
        name: check('.wrong_format') { false }
      )
  end

schema.({id: 1, name: 'wrong'}).errors # {name: ['wrong format']}
```

When feasible, format yaml file in accordance with the default casters' keys. However, with this approach often key names wouldn't make much sense in the application context:

```yml
en:
  user:
    check: User has not been found
    name:
      check: wrong format
```

```ruby
schema =
  # Only root scope is set, no other boilerplate
  Datacaster.schema(i18n_scope: 'user') do
    check { |v| v[:id] == 1 } &
      hash_schema(
        name: check { false }
      )
  end

schema.({id: 3}).errors # ['User has not been found']
schema.({id: 1, name: 'wrong'}).errors # {name: ['wrong format']}
```

Use `#raw_errors` instead of `#errors` to get errors just before the I18n backend is called. This will allow to see all the i18n keys in the order of priority which will be used to produce final error messages.

Notice that the use of `.i18n_scope` prevents auto-scoping of hash key:

```ruby
schema =
  # Only root scope is set, no other boilerplate
  Datacaster.schema(i18n_scope: 'user') do
    hash_schema(
      name: check { false }.i18n_scope('.data')
    )
  end

# will search for the following keys:
# - "user.data.check"
# - "datacaster.errors.check"
schema.(name: 'john').raw_errors
```

### Providing interpolation variables

Every caster will automatically provide `value` variable for i18n interpolation.

All keyword arguments of `#i18n_key`, `#i18n_scope` and designed for that sole purpose `#i18n_vars` are provided as interpolation variables on i18n.

It is possible to add i18n variables at the runtime (e.g. inside `check { ... }` block) by calling `i18n_vars!(variable: 'value')` or `i18n_var!(:variable, 'value')`.

Outer calls of `#i18n_key` (`#i18n_scope`, `#i18n_vars`) have presedence before the inner if variable names collide. However, runtime calls of `#i18n_vars!` and `#i18n_var!` overwrite compile-time variables from the next nearest key, scope or vars on collision.

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
