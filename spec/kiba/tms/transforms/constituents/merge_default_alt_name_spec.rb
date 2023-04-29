# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::Constituents::MergeDefaultAltName do
  let(:accumulator) { [] }
  let(:test_job) {
    Helpers::TestJob.new(input: input, accumulator: accumulator,
      transforms: transforms)
  }
  let(:result) { test_job.accumulator }
  let(:transforms) do
    alt_names = {
      "1" => [{displayname: "a b", alphasort: "b a"}],
      "3" => []
    }

    Kiba.job_segment do
      transform Kiba::Tms::Transforms::Constituents::MergeDefaultAltName,
        alt_names: alt_names
    end
  end
  let(:input) do
    [
      {displayname: "a", alphasort: "b", defaultnameid: "1"},
      {displayname: "z y", alphasort: "y z", defaultnameid: "3"}
    ]
  end

  context "with preferred name field = displayname" do
    let(:expected) do
      [
        "a b",
        nil
      ]
    end

    it "transforms as expected" do
      expect(result.map { |row| row[:alt_displayname] }).to eq(expected)
    end
  end

  context "with preferred name field = alpHasort" do
    before { Kiba::Tms::Constituents.config.preferred_name_field = :alphasort }
    let(:expected) do
      [
        "b a",
        nil
      ]
    end

    it "transforms as expected" do
      expect(result.map { |row| row[:alt_alphasort] }).to eq(expected)
    end
  end
end
