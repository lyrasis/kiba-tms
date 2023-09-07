# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::Locations::AddLocationName do
  subject(:xform) { described_class.new }
  let(:result) { input.map { |row| xform.process(row) } }
  let(:locnames) { result.map { |row| row[:location_name] } }
  let(:input) do
    [
      {brief_address: "a", site: "b", room: "c", unittype: "d",
       unitnumber: "e", unitposition: "f"},
      {brief_address: "a", site: "b", room: "c", unittype: nil, unitnumber: "",
       unitposition: "f"},
      {brief_address: "a", site: "", room: "c", unittype: "", unitnumber: "e",
       unitposition: nil},
      {other_data: "blah"}
    ]
  end

  context "when append to types = none" do
    it "adds location_name field as expected" do
      delim = Tms::Locations.hierarchy_delim
      expected = [
        ["a", "b", "c", "d e", "f"].join(delim),
        ["a", "b", "c", "f"].join(delim),
        ["a", "c", "e"].join(delim),
        nil
      ]
      expect(locnames).to eq(expected)
    end
  end
end
