require "complex"
require "./spec_helper"

struct Simple
  include MassAssignable

  getter foo : String
  getter bar : Int32

  def initialize(_ignore, @foo, @bar)
  end
end

struct Nested
  include MassAssignable

  getter inner : Simple
  getter outer : String

  def initialize(_ignore, @inner, @outer)
  end
end

module ComplexConverter
  def from_attribute(value)
    Complex.new(value[:r], value[:i])
  end

  def to_attribute(value)
    {r: value.real, i: value.imag}
  end

  extend self
end

struct WithConversion
  include MassAssignable

  @[MassAssignable::Field(converter: ComplexConverter)]
  getter value : Complex
  getter other_value : Int32

  def initialize(_ignore, @value, @other_value)
  end
end

struct WithKeyRename
  include MassAssignable

  getter value : Int32
  @[MassAssignable::Field(key: "otherValue")]
  getter other_value : Int32

  def initialize(_ignore, @value, @other_value)
  end
end

struct WithIgnoredField
  include MassAssignable

  getter value : Int32
  @[MassAssignable::Field(ignore: key)]
  getter other_value : Int32?

  def initialize(_ignore, @value, @other_value)
  end
end

struct WithRoot
  include MassAssignable

  @[MassAssignable::Field(root: "inner")]
  getter simple : Simple
  getter outer : String

  def initialize(_ignore, @simple, @outer)
  end
end

class Mutable
  include MassAssignable

  property foo : String
  property bar : Int32
  getter baz : String
end

describe MassAssignable do
  describe ".new" do
    context "simple" do
      it "coerces correctly" do
        instance = Simple.new(foo: "bar", bar: 2)
        instance.foo.should eq("bar")
        instance.bar.should eq(2)
      end
    end

    context "nested" do
      it "coerces correctly" do
        instance = Nested.new(inner: {foo: "bar", bar: 2}, outer: "foo")
        instance.outer.should eq("foo")
        instance.inner.foo.should eq("bar")
        instance.inner.bar.should eq(2)
      end
    end

    context "with conversion" do
      it "coerces correctly" do
        instance = WithConversion.new(value: {r: 1, i: 2}, other_value: 3)
        instance.value.should eq(Complex.new(1, 2))
        instance.other_value.should eq(3)
      end
    end

    context "with key rename" do
      it "coerces correctly" do
        instance = WithKeyRename.new(value: 1, otherValue: 2)
        instance.value.should eq(1)
        instance.other_value.should eq(2)
      end
    end

    context "with ignored field" do
      it "coerces correctly" do
        instance = WithIgnoredField.new(value: 1, other_value: 2)
        instance.value.should eq(1)
        instance.other_value.should be_nil
      end
    end

    context "with root" do
      it "coerces correctly" do
        instance = WithRoot.new(
          simple: {inner: {foo: "bar", bar: 2}}, outer: "foo"
        )
        instance.simple.foo.should eq("bar")
        instance.simple.bar.should eq(2)
        instance.outer.should eq("foo")
      end
    end
  end

  describe ".from_attribute" do
    context "simple" do
      it "coerces correctly" do
        instance = Simple.from_attribute({foo: "bar", bar: 2})
        instance.foo.should eq("bar")
        instance.bar.should eq(2)
      end
    end

    context "nested" do
      it "coerces correctly" do
        instance = Nested.from_attribute({inner: {foo: "bar", bar: 2}, outer: "foo"})
        instance.outer.should eq("foo")
        instance.inner.foo.should eq("bar")
        instance.inner.bar.should eq(2)
      end
    end

    context "with conversion" do
      it "coerces correctly" do
        instance = WithConversion.from_attribute({value: {r: 1, i: 2}, other_value: 3})
        instance.value.should eq(Complex.new(1, 2))
        instance.other_value.should eq(3)
      end
    end

    context "with key rename" do
      it "coerces correctly" do
        instance = WithKeyRename.from_attribute({value: 1, otherValue: 2})
        instance.value.should eq(1)
        instance.other_value.should eq(2)
      end
    end

    context "with ignored field" do
      it "coerces correctly" do
        instance = WithIgnoredField.from_attribute({value: 1, other_value: 2})
        instance.value.should eq(1)
        instance.other_value.should be_nil
      end
    end
  end

  describe "#to_attribute" do
    context "simple" do
      it "coerces correctly" do
        instance = Simple.new(:ignore, "bar", 2)
        instance.to_attribute.should eq({foo: "bar", bar: 2})
      end
    end

    context "nested" do
      it "coerces correctly" do
        inner = Simple.new(:ignore, "bar", 2)
        instance = Nested.new(:ignore, inner, "foo")
        instance.to_attribute.should eq({
          inner: {foo: "bar", bar: 2}, outer: "foo",
        })
      end
    end

    context "with conversion" do
      it "coerces correctly" do
        instance = WithConversion.new(:ignore, Complex.new(1, 2), 3)
        instance.to_attribute.should eq({
          value: {r: 1, i: 2}, other_value: 3,
        })
      end
    end

    context "with key rename" do
      it "coerces correctly" do
        instance = WithKeyRename.new(:ignore, 1, 2)
        instance.to_attribute.should eq({
          value: 1, otherValue: 2,
        })
      end
    end

    context "with ignored field" do
      it "coerces correctly" do
        instance = WithIgnoredField.new(:ignore, 1, 2)
        instance.to_attribute.should eq({value: 1})
      end
    end

    context "with root" do
      it "coerces correctly" do
        simple = Simple.new(:ignore, "bar", 2)
        instance = WithRoot.new(:ignore, simple, "foo")
        instance.to_attribute.should eq({
          simple: {
            inner: {foo: "bar", bar: 2},
          },
          outer: "foo",
        })
      end
    end
  end

  describe "#attributes=" do
    it "allows mass assigning mutable fields" do
      instance = Mutable.new(foo: "bar", bar: 2, baz: "foobar")
      instance.attributes = {foo: "baz"}
      instance.foo.should eq("baz")
      instance.bar.should eq(2)
      instance.baz.should eq("foobar")
    end
  end
end

require "./mass_assignable/*"
