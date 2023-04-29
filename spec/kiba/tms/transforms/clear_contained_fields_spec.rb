# frozen_string_literal: true

RSpec.describe Kiba::Tms::Transforms::ClearContainedFields do
  subject(:xform) { described_class.new(**params) }
  let(:results) { input.map { |row| xform.process(row) } }
  let(:params) { {a: :a, b: :b} }

  context "blank vals" do
    let(:input) do
      [
        {a: "", b: ""},
        {a: nil, b: ""},
        {a: nil, b: nil},
        {a: nil, b: "foo"},
        {a: "foo", b: nil}
      ]
    end
    let(:expected) do
      [
        {a: "", b: ""},
        {a: nil, b: ""},
        {a: nil, b: nil},
        {a: nil, b: "foo"},
        {a: "foo", b: nil}
      ]
    end

    it "returns expected" do
      expect(results).to eq(expected)
    end
  end

  context "single vals" do
    let(:input) do
      [
        {a: "foo", b: "Foo"},
        {a: "Food", b: "foo"},
        {a: "foo", b: "food"},
        {a: "foo", b: "boo"},
        {a: "foo-foo", b: "Foo--foo."}
      ]
    end
    let(:expected) do
      [
        {a: "foo", b: nil},
        {a: "Food", b: nil},
        {a: nil, b: "food"},
        {a: "foo", b: "boo"},
        {a: "foo-foo", b: nil}
      ]
    end

    it "returns expected" do
      expect(results).to eq(expected)
    end
  end

  context "with b_only" do
    let(:input) do
      [
        {a: "foo", b: "Foo"},
        {a: "Food", b: "foo"},
        {a: "foo", b: "food"},
        {a: "foo", b: "boo"},
        {a: "foo-foo", b: "Foo--foo."}
      ]
    end
    let(:params) { {a: :a, b: :b, b_only: true} }
    let(:expected) do
      [
        {a: "foo", b: nil},
        {a: "Food", b: nil},
        {a: "foo", b: "food"},
        {a: "foo", b: "boo"},
        {a: "foo-foo", b: nil}
      ]
    end

    it "returns expected" do
      expect(results).to eq(expected)
    end
  end

  context "multi vals" do
    let(:input) do
      [
        {a: "foo|bar", b: "Bar|Foo"},
        {a: "Bar|Food", b: "foo|baz"},
        {a: "foo|baz", b: "bar|food"},
        {a: "foo|moo", b: "boo|too"}
      ]
    end
    let(:params) { {a: :a, b: :b, delim: "|"} }
    let(:expected) do
      [
        {a: "foo|bar", b: nil},
        {a: "Bar|Food", b: "baz"},
        {a: "baz", b: "bar|food"},
        {a: "foo|moo", b: "boo|too"}
      ]
    end

    it "returns expected" do
      expect(results).to eq(expected)
    end
  end

  context "with casesensitive: true and normalized: true" do
    let(:params) { {a: :a, b: :b, casesensitive: true} }
    let(:input) do
      [
        {a: "foo", b: "Foo"},
        {a: "Food", b: "foo"},
        {a: "foo", b: "food"},
        {a: "foo", b: "boo"},
        {a: "foo-foo", b: "foo--foo."},
        {a: "foo-foo", b: "Foo--foo."}
      ]
    end
    let(:expected) do
      [
        {a: "foo", b: "Foo"},
        {a: "Food", b: "foo"},
        {a: nil, b: "food"},
        {a: "foo", b: "boo"},
        {a: "foo-foo", b: nil},
        {a: "foo-foo", b: "Foo--foo."}
      ]
    end

    it "returns expected" do
      expect(results).to eq(expected)
    end
  end

  context "with casesensitive: true and normalized: false" do
    let(:params) { {a: :a, b: :b, casesensitive: true, normalized: false} }
    let(:input) do
      [
        {a: "foo", b: "Foo"},
        {a: "Food", b: "foo"},
        {a: "foo", b: "food"},
        {a: "foo", b: "boo"},
        {a: "foo-foo", b: "foo--foo."},
        {a: "foo-foo", b: "Foo--foo."}
      ]
    end
    let(:expected) do
      [
        {a: "foo", b: "Foo"},
        {a: "Food", b: "foo"},
        {a: nil, b: "food"},
        {a: "foo", b: "boo"},
        {a: "foo-foo", b: "foo--foo."},
        {a: "foo-foo", b: "Foo--foo."}
      ]
    end

    it "returns expected" do
      expect(results).to eq(expected)
    end
  end

  context "with casesensitive: false and normalized: false" do
    let(:params) { {a: :a, b: :b, normalized: false} }
    let(:input) do
      [
        {a: "foo", b: "Foo"},
        {a: "Food", b: "foo"},
        {a: "foo", b: "food"},
        {a: "foo", b: "boo"},
        {a: "foo-foo", b: "foo--foo."},
        {a: "foo-foo", b: "Foo--foo."}
      ]
    end
    let(:expected) do
      [
        {a: "foo", b: nil},
        {a: "Food", b: nil},
        {a: nil, b: "food"},
        {a: "foo", b: "boo"},
        {a: "foo-foo", b: "foo--foo."},
        {a: "foo-foo", b: "Foo--foo."}
      ]
    end

    it "returns expected" do
      expect(results).to eq(expected)
    end
  end
end
