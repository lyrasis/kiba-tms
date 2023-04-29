# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::Names::NotKept do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }
  let(:transforms) do
    Kiba.job_segment do
      transform Kiba::Tms::Transforms::Names::NotKept
    end
  end
  let(:input) do
    [
      {migration_action: ""},
      {migration_action: nil},
      {something_else: "foo"},
      {migration_action: "add_contact"},
      {migration_action: "main"},
      {migration_action: "merge_variant"},
      {migration_action: "ok"},
      {migration_action: "use_name"},
    ]
  end

  let(:expected) do
    [
      {migration_action: "add_contact"},
      {migration_action: "merge_variant"},
      {migration_action: "use_name"},
    ]
  end
  
  it "transforms as expected" do
    expect(result).to eq(expected)
  end
end
