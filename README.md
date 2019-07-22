# MassAssignable

MassAssignable brings mass assignment to your classes! Especially useful for
filling immutable structs on initialization. Handles arbitrarily deep nesting
and common types such as Arrays, Hashes, Tuples, NamedTuples, etc.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     mass_assignable:
       gitlab: repomaa/mass_assignable
   ```

2. Run `shards install`

## Usage

Include `MassAssignable` in your class/struct. It will generate an initializer,
which accepts named arguments for all of your instance variables and a
`#to_attribute` method which will return a `NamedTuple` with the values of the
instance variables.

Both work recursively so you can use builtin types and all the way down in
nested structures as input to the initializer. `#to_attribute` will also
coerce nested structures into a named tuple of builtin types.

### Annotations

#### `ignore`

To exclude an instance variables use the `@[MassAssignable::Field(ignore: true)]`
annotation.

#### `converter`

To specify how a value should be coerced you can set
`@[MassAssignable::Field(converter: ConverterClass)]` where `ConverterClass` is
a module/class with a class method `from_attribute` that takes an attribute of
whatever type is used in the named args and returns an instance of the type
defined for the instance variable. To use `MassAssignable#to_attribute` the
converter also has to implement a `to_attribute` class method which gets the
value of the instance variable and should return a value of the type expected
for the key in the resulting `NamedTuple`.

#### `root`

Parses the value of the given attribute in a named tuple with the key defined
with the `@[MassAssignable::Field(root: "foo")` annotation. In this case it
would look for the value to coerce inside a nested structure under the key
`foo`.

### Example

```crystal
require "mass_assignable"

struct Inner
  include MassAssignable

  getter foobar : Int32
end

module CSVConverter
  def from_attribute(string : String)
    string.split(',').map(&.strip)
  end

  def to_attribute(values)
    values.join(',')
  end

  extend self
end

struct Test
  include MassAssignable

  @[MassAssignable::Field(converter: CSVConverter)]
  getter foo : Array(String)
  @[MassAssignable::Field(ignore: true)]
  getter bar : Int32?
  getter baz : Tuple(Inner, Inner)
  @[MassAssignable::Field(key: "fooBar")]
  getter foobar : Hash(Int32, Tuple(Inner, Inner))
  @[MassAssignable::Field(key: "bar_foo")]
  getter barfoo : StaticArray(Int32, 3)
end

pp test = Test.new(
  foo: "foo,bar",
  bar: 2,
  baz: [
    Inner.new(foobar: 1),
    { foobar: 2 }
  ],
  fooBar: {
    2 => [
      {foobar: 1},
      Inner.new(foobar: 2)
    ]
  },
  bar_foo: { 1, 2, 3 }
) # =>
# Test(
#   @bar=nil,
#   @barfoo=StaticArray[Inner(@foobar=1), Inner(@foobar=2), Inner(@foobar=3)],
#   @baz={Inner(@foobar=1), Inner(@foobar=2)},
#   @foo=["foo", "bar"],
#   @foobar={2 => {Inner(@foobar=1), Inner(@foobar=2)}}
# )

pp test.to_attribute # =>
# {
#   foo: "foo,bar",
#   baz: {{foobar: 1}, {foobar: 2}},
#   fooBar: {2 => {{foobar: 1}, {foobar: 2}}},
#   bar_foo: {{foobar: 1}, {foobar: 2}, {foobar: 3}}
# }
```

## Contributing

1. Fork it (<https://gitlab.com/repomaa/mass_assignable/forks/new>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write a spec
4. Implement your feature
5. Check that specs are green
6. Commit your changes (`git commit -am 'Add some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create a new Merge Request

## Contributors

- [Joakim Repomaa](https://gitlab.com/repomaa) - creator and maintainer
