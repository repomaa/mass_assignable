require "../spec_helper"

describe Object do
  describe ".from_attribute" do
    context "self" do
      it "coerces correctly" do
        Int32.from_attribute(1).should eq(1)
      end
    end
  end
end

describe Array do
  describe ".from_attribute" do
    context "self" do
      it "coerces correctly" do
        Array(Int32).from_attribute([1, 2, 3]).should eq([1, 2, 3])
      end
    end

    context "Enumerable" do
      it "coerces correctly" do
        Array(Int32).from_attribute(Set{1, 2, 3}).should eq([1, 2, 3])
      end
    end

    context "Enumerable of non-primitive types" do
      it "coerces correctly" do
        Array(Tuple(Int32, Int32)).from_attribute(Set{[1, 2], [3, 4]}).should eq(
          [{1, 2}, {3, 4}]
        )
      end
    end
  end
end

describe Set do
  describe ".from_attribute" do
    context "self" do
      it "coerces correctly" do
        Set(Int32).from_attribute(Set{1, 2, 3}).should eq(Set{1, 2, 3})
      end
    end

    context "Enumerable" do
      it "coerces correctly" do
        Set(Int32).from_attribute([1, 2, 3]).should eq(Set{1, 2, 3})
      end
    end

    context "Enumerable of non-primitive types" do
      it "coerces correctly" do
        Set(Tuple(Int32, Int32)).from_attribute([{1, 2}, [3, 4]]).should eq(
          Set{ {1, 2}, {3, 4} }
        )
      end
    end
  end
end

describe StaticArray do
  describe ".from_attribute" do
    context "self" do
      it "coerces correctly" do
        StaticArray(Int32, 3).from_attribute(StaticArray[1, 2, 3]).should eq(
          StaticArray[1, 2, 3]
        )
      end
    end

    context "Indexable" do
      it "coerces correctly" do
        StaticArray(Int32, 3).from_attribute([1, 2, 3]).should eq(
          StaticArray[1, 2, 3]
        )
      end
    end

    context "Indexable of non-primitive types" do
      it "coerces correctly" do
        StaticArray(Tuple(Int32, Int32), 3).from_attribute([
          [1, 2],
          Set{3, 4},
          StaticArray[5, 6],
        ]).should eq(StaticArray[{1, 2}, {3, 4}, {5, 6}])
      end
    end
  end
end

describe Tuple do
  describe ".from_attribute" do
    context "self" do
      it "coerces correctly" do
        Tuple(Int32, Int32, Int32).from_attribute({1, 2, 3}).should eq({1, 2, 3})
      end
    end

    context "Tuple of non-primitive types" do
      it "coerces correctly" do
        Tuple(Tuple(Int32, String), Array(Int32)).from_attribute(
          { {1, "foo"}, {2, 3} }
        ).should eq({ {1, "foo"}, [2, 3] })
      end
    end

    context "Indexable" do
      it "coerces correctly" do
        Tuple(Int32, Int32, Int32).from_attribute([1, 2, 3]).should eq({1, 2, 3})
      end
    end

    context "Indexable of non-primitive types" do
      it "coerces correctly" do
        Tuple(Tuple(Int32, String), Array(Int32)).from_attribute(
          [[1, "foo"], [2, 3]]
        ).should eq({ {1, "foo"}, [2, 3] })
      end
    end

    context "Enumerable" do
      it "coerces correctly" do
        Tuple(Int32, Int32, Int32).from_attribute(Set{1, 2, 3}).should eq({1, 2, 3})
      end
    end

    context "Enumerable of non-primitive types" do
      it "coerces correctly" do
        Tuple(Tuple(Int32, String), Array(Int32)).from_attribute(
          Set{Set{1, "foo"}, Set{2, 3}}
        ).should eq({ {1, "foo"}, [2, 3] })
      end
    end
  end
end

describe NamedTuple do
  describe ".from_attribute" do
    context "self" do
      it "coerces correctly" do
        NamedTuple(foo: String, bar: Int32).from_attribute(
          {foo: "bar", bar: 2}
        ).should eq({foo: "bar", bar: 2})
      end
    end

    context "NamedTuple of non-primitive types" do
      it "coerces correctly" do
        NamedTuple(
          foo: Tuple(Int32, String),
          bar: NamedTuple(foobar: String)).from_attribute(
          {foo: [2, "bar"], bar: {foobar: "foo"}}
        ).should eq({foo: {2, "bar"}, bar: {foobar: "foo"}})
      end
    end

    context "Hash with string keys" do
      NamedTuple(foo: String, bar: Int32).from_attribute({
        "foo" => "bar",
        "bar" => 2,
      }).should eq({foo: "bar", bar: 2})
    end

    context "Hash with symbol keys" do
      NamedTuple(foo: String, bar: Int32).from_attribute({
        :foo => "bar",
        :bar => 2,
      }).should eq({foo: "bar", bar: 2})
    end

    context "Hash of non-primitive type values" do
      it "coerces correctly" do
        NamedTuple(
          foo: Tuple(Int32, String),
          bar: NamedTuple(foobar: String)).from_attribute(
          {"foo" => [2, "bar"], "bar" => {"foobar" => "foo"}}
        ).should eq({foo: {2, "bar"}, bar: {foobar: "foo"}})
      end
    end
  end
end

describe Hash do
  describe ".from_attribute" do
    context "self" do
      it "coerces correctly" do
        Hash(String, Int32 | String).from_attribute({
          "foo" => "bar",
          "bar" => 2,
        }).should eq({"foo" => "bar", "bar" => 2})
      end
    end

    context "NamedTuple" do
      it "coerces correctly" do
        Hash(String, Int32 | String).from_attribute({
          foo: "bar",
          bar: 2,
        }).should eq({"foo" => "bar", "bar" => 2})
      end
    end

    context "NamedTuple with non-primitive type values" do
      it "coerces correctly" do
        Hash(String, Int32 | Tuple(String, Int32) | Hash(String, Int32)).from_attribute({
          foo: 1,
          bar: ["foo", 2],
          baz: {foobar: 2},
        }).should eq({"foo" => 1, "bar" => {"foo", 2}, "baz" => {"foobar" => 2}})
      end
    end

    context "Hash with non-primitive type values" do
      it "coerces correctly" do
        Hash(String, Int32 | Tuple(String, Int32) | NamedTuple(foobar: Int32)).from_attribute({
          "foo" => 1,
          "bar" => ["foo", 2],
          "baz" => {"foobar" => 2},
        }).should eq({"foo" => 1, "bar" => {"foo", 2}, "baz" => {foobar: 2}})
      end
    end
  end
end

describe Union do
  describe ".from_attribute" do
    context "self" do
      it "coerces correctly" do
        Union(Int32, String, Float64).from_attribute(
          "foo".as(Union(Int32, String, Float64))
        ).should eq("foo")
      end
    end

    context "non-primitive values" do
      it "coerces correctly" do
        Union(Hash(String, Int32 | String), Tuple(String, Int32), Float64).from_attribute(
          {foo: 2, bar: "baz"}
        ).should eq({"foo" => 2, "bar" => "baz"})
      end
    end
  end
end
