# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::Locations::AddParent do
  subject(:xform) { described_class.new }
  let(:result) { input.map { |row| xform.process(row) } }
  let(:input) do
    [
      {location_name: ""},
      {location_name: nil},
      {other_data: "blah"},
      {location_name: "a"},
      {location_name: "a > b"},
      {location_name: "a > b > c"}
    ]
  end

  it "adds parent location as expected" do
    expected = [
      nil,
      nil,
      nil,
      nil,
      "a",
      "a > b"
    ]
    expect(result.map { |row| row[:parent_location] }).to eq(expected)
  end
end
