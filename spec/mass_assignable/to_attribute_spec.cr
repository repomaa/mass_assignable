require "../spec_helper"

struct TestStruct
  include MassAssignable

  property foo : String

  def initialize(@foo)
  end
end

describe Object do
  describe "#to_attribute" do
    it "coerces correctly" do
      1.to_attribute.should eq(1)
    end
  end
end

describe Enumerable do
  describe "#to_attribute" do
    context "with primitive types" do
      it "coerces correctly" do
        [1, 2, 3].to_attribute.should eq([1, 2, 3])
        {1, 2, 3}.to_attribute.should eq({1, 2, 3})
        Set{1, 2, 3}.to_attribute.should eq([1, 2, 3])
      end
    end

    context "with non-primitive types" do
      it "coerces correctly" do
        [{1, TestStruct.new("bar")}, [3, 4]].to_attribute.should eq(
          [{1, { foo: "bar" }}, [3, 4]]
        )

        { {1, TestStruct.new("bar") }, [3, 4] }.to_attribute.should eq(
          { {1, { foo: "bar" }}, [3, 4] }
        )

        Set{ {1, TestStruct.new("bar")}, [3, 4] }.to_attribute.should eq(
          [{1, { foo: "bar" }}, [3, 4]]
        )
      end
    end
  end
end

describe NamedTuple do
  describe "#to_attribute" do
    context "with primitive types" do
      it "coerces correctly" do
        { foo: "bar", bar: 2 }.to_attribute.should eq({ foo: "bar", bar: 2})
      end
    end

    context "with non-primitive types" do
      it "coerces correctly" do
        { foo: TestStruct.new("bar"), bar: [3, 4] }.to_attribute.should eq(
          { foo: { foo: "bar" }, bar: [3, 4] }
        )
      end
    end
  end
end

describe Hash do
  describe "#to_attribute" do
    context "with primitive types" do
      it "coerces correctly" do
        { "foo" => "bar", "bar" => 2 }.to_attribute.should eq({
          "foo" => "bar",
          "bar" => 2
        })
      end
    end

    context "with non-primitive types" do
      it "coerces correctly" do
        { "foo" => TestStruct.new("bar"), "bar" => [3, 4] }.to_attribute.should eq(
          { "foo" => { foo: "bar" }, "bar" => [3, 4] }
        )
      end
    end
  end
end

describe StaticArray do
  describe "#to_attribute" do
    context "with primitive types" do
      it "coerces correctly" do
        StaticArray[1, 2, 3].to_attribute.should eq({ 1, 2, 3 })
      end
    end

    context "with non-primitive types" do
      it "coerces correctly" do
        StaticArray[{1, TestStruct.new("bar")}, [3, 4]].to_attribute.should eq(
          { {1, { foo: "bar" }}, [3, 4] }
        )
      end
    end
  end
end
