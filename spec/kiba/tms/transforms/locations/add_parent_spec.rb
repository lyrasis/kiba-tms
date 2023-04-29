# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::Locations::AddParent do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator.map{ |row| row[:parent_location] } }
  let(:transforms) do
    Kiba.job_segment do
      transform Kiba::Tms::Transforms::Locations::AddParent
    end
  end
  let(:input) do
    [
      {location_name: ""},
      {location_name: nil},
      {other_data: "blah"},
      {location_name: "a"},
      {location_name: "a >> b"},
      {location_name: "a >> b >> c"}
    ]
  end

  it "adds parent location as expected" do
    expected = [
      nil,
      nil,
      nil,
      nil,
      "a",
      "a >> b"
      ]
    expect(result).to eq(expected)
  end
end
