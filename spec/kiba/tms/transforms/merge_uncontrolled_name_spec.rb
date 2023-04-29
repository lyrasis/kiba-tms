# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::MergeUncontrolledName do
  subject(:xform) { described_class.new(**params) }

  describe "#process" do
    let(:results) { input.map { |row| xform.process(row) } }
    let(:lookup) do
      {
        "janedoe" => [{
          person: "Jane Doe",
          organization: nil,
          note: nil
        }],
        "johndoe" => [{
          person: "John Doe",
          organization: nil,
          note: nil
        }],
        "vanguard" => [{
          person: "Vanguard (artist)",
          organization: "Vanguard, Inc.",
          note: nil
        }],
        "possibleformerownerartist" => [{
          person: nil,
          organization: nil,
          note: "Possible former owner: Artist"
        }]
      }
    end

    context "with single values" do
      let(:params) { {field: :name, lookup: lookup} }
      let(:input) do
        [
          {name: "Jane.Doe"},
          {name: "Vanguard"},
          {name: "Possible former owner, Artist"},
          {name: "Not present"},
          {name: nil},
          {name: ""},
          {foo: "bar"}
        ]
      end
      let(:expected) do
        [
          {name_person: "Jane Doe", name_org: nil, name_note: nil},
          {name_person: "Vanguard (artist)",
           name_org: "Vanguard, Inc.",
           name_note: nil},
          {name_person: nil,
           name_org: nil,
           name_note: "Possible former owner: Artist"},
          {name_person: nil,
           name_org: nil,
           name_note: nil},
          {name_person: nil,
           name_org: nil,
           name_note: nil},
          {name_person: nil,
           name_org: nil,
           name_note: nil},
          {foo: "bar",
           name_person: nil,
           name_org: nil,
           name_note: nil}
        ]
      end

      it "transforms as expected" do
        expect(results).to eq(expected)
      end
    end

    context "with multikey values" do
      let(:params) { {field: :name, lookup: lookup, delim: "|"} }
      let(:input) do
        [
          {name: "Jane.Doe|John.Doe|Possible former owner, Artist"},
          {name: "Jane.Doe|Vanguard"}
        ]
      end
      let(:expected) do
        [
          {name_person: "Jane Doe|John Doe",
           name_org: nil,
           name_note: "Possible former owner: Artist"},
          {name_person: "Jane Doe|Vanguard (artist)",
           name_org: "Vanguard, Inc.",
           name_note: nil}
        ]
      end

      it "transforms as expected" do
        expect(results).to eq(expected)
      end
    end
  end
end
