# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::Locations::AddLocationName do
  let(:accumulator) { [] }
  let(:test_job) {
    Helpers::TestJob.new(input: input, accumulator: accumulator,
      transforms: transforms)
  }
  let(:result) { test_job.accumulator }
  let(:transforms) do
    Kiba.job_segment do
      transform Kiba::Tms::Transforms::Locations::AddLocationName
    end
  end
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
      expected = [
        "a >> b >> c >> d e >> f",
        "a >> b >> c >> f",
        "a >> c >> e",
        nil
      ]
      expect(locnames).to eq(expected)
    end
  end
end
