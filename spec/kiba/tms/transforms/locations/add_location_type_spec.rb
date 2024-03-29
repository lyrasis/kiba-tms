# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::Locations::AddLocationType do
  subject(:xform) { described_class.new }
  let(:result) { input.map { |row| xform.process(row) } }
  let(:input) do
    [
      {location_name: ""},
      {location_name: nil},
      {other_data: "blah"},
      {location_name: "a > b > c"},
      {location_name: "a > Director's Office"},
      {location_name: "a > Office of something"},
      {location_name: "a > Prep room"},
      {location_name: "a > Curator's Office > Curator's Cabinet > Bottom Drawer"},
      {location_name: "a > Curator's Office > Curator's Cabinet > drawer a"},
      {location_name: "a > Curator's Office > Curator's Cabinet > Top shelf"},
      {location_name: "a > Curator's Office > Curator's Cabinet > Shelf Q"},
      {location_name: "a > Unit 2"},
      {location_name: "a > Room 7 > Tray 2"},
      {location_name: "a > Room 7 > Cabinet > Bottom tray"},
      {location_name: "a > Room 7 > Box10"},
      {location_name: "a > Room 7 > Box 10"},
      {location_name: "a > Room 7 > Storage Box"},
      {location_name: "a > Room 7 > Case10"},
      {location_name: "a > Room 7 > Case 10"},
      {location_name: "a > Room 7 > Storage Case"}
    ]
  end

  it "adds parent location as expected" do
    expected = [
      nil,
      nil,
      nil,
      nil,
      "Room",
      "Room",
      "Room",
      "Drawer",
      "Drawer",
      "Shelf",
      "Shelf",
      "Unit",
      "Tray",
      "Tray",
      "Box",
      "Box",
      "Box",
      "Case",
      "Case",
      "Case"
    ]
    expect(result.map { |row| row[:locationtype] }).to eq(expected)
  end
end
