# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::ObjLocations::TemptextMappings do
  subject(:xform){ described_class.new }
  let(:result){ input.map{ |row| xform.process(row) } }

  let(:input) do
    [
      {temptext: "foo", ttmapping: "drop", ttcorrect: nil},
      {temptext: "foo", ttmapping: "loc2", ttcorrect: nil},
      {temptext: "foo", ttmapping: "loc4", ttcorrect: nil},
      {temptext: "foo", ttmapping: "loc6", ttcorrect: nil},
      {temptext: "foo", ttmapping: "currentlocationnote", ttcorrect: nil},
      {temptext: "foo", ttmapping: "movementnote", ttcorrect: nil},
      {temptext: "foo", ttmapping: "inventorynote", ttcorrect: nil},
      {temptext: "foo", ttmapping: "loc2", ttcorrect: "fixed"},
      {temptext: "foo", ttmapping: "loc4", ttcorrect: "fixed"},
      {temptext: "foo", ttmapping: "loc6", ttcorrect: "fixed"},
      {temptext: "foo", ttmapping: "currentlocationnote", ttcorrect: "fixed"},
      {temptext: "foo", ttmapping: "movementnote", ttcorrect: "fixed"},
      {temptext: "foo", ttmapping: "inventorynote", ttcorrect: "fixed"}
    ]
  end

  let(:expected) do
    [
      {temptext: "foo",
       loc2: nil, loc4: nil, loc6: nil,
       currentlocationnote: nil,
       movementnote: nil,
       inventorynote: nil},
      {temptext: "foo",
       loc2: "foo", loc4: nil, loc6: nil,
       currentlocationnote: nil,
       movementnote: nil,
       inventorynote: nil},
      {temptext: "foo",
       loc2: nil, loc4: "foo", loc6: nil,
       currentlocationnote: nil,
       movementnote: nil,
       inventorynote: nil},
      {temptext: "foo",
       loc2: nil, loc4: nil, loc6: "foo",
       currentlocationnote: nil,
       movementnote: nil,
       inventorynote: nil},
      {temptext: "foo",
       loc2: nil, loc4: nil, loc6: nil,
       currentlocationnote: "foo",
       movementnote: nil,
       inventorynote: nil},
      {temptext: "foo",
       loc2: nil, loc4: nil, loc6: nil,
       currentlocationnote: nil,
       movementnote: "foo",
       inventorynote: nil},
      {temptext: "foo",
       loc2: nil, loc4: nil, loc6: nil,
       currentlocationnote: nil,
       movementnote: nil,
       inventorynote: "foo"},
      {temptext: "foo",
       loc2: "fixed", loc4: nil, loc6: nil,
       currentlocationnote: nil,
       movementnote: nil,
       inventorynote: nil},
      {temptext: "foo",
       loc2: nil, loc4: "fixed", loc6: nil,
       currentlocationnote: nil,
       movementnote: nil,
       inventorynote: nil},
      {temptext: "foo",
       loc2: nil, loc4: nil, loc6: "fixed",
       currentlocationnote: nil,
       movementnote: nil,
       inventorynote: nil},
      {temptext: "foo",
       loc2: nil, loc4: nil, loc6: nil,
       currentlocationnote: "fixed",
       movementnote: nil,
       inventorynote: nil},
      {temptext: "foo",
       loc2: nil, loc4: nil, loc6: nil,
       currentlocationnote: nil,
       movementnote: "fixed",
       inventorynote: nil},
      {temptext: "foo",
       loc2: nil, loc4: nil, loc6: nil,
       currentlocationnote: nil,
       movementnote: nil,
       inventorynote: "fixed"},
    ]
  end

  it "transforms as expected" do
    expect(result).to eq(expected)
  end

  context "with unknown mapping" do
    let(:input) do
      [
        {temptext: "foo", ttmapping: "nope", ttcorrect: nil}
      ]
    end

    it "raises error" do
      expect{ result }.to raise_error(
        Tms::UnknownObjLocTempTextMappingError,
        /nope/
      )
    end
  end
end
