# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Tms::Transforms::ConAddress::RemoveRedundantAddressLines do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }
  let(:transforms) do
    Kiba.job_segment do
      transform Kiba::Tms::Transforms::ConAddress::RemoveRedundantAddressLines
    end
  end
  let(:input) do
    [
      {alphasort: 'b, a', displayname: 'a b', displayname1: 'ab'},
      {alphasort: 'c, d', displayname: 'd c', displayname1: 'd c'},
      {alphasort: 'e, f', displayname: 'f e', displayname1: 'e, f'},
      {alphasort: 'g, h', displayname: 'h g', displayname1: 'hg', displayname2: 'g, h'},
      {alphasort: 'i, j', displayname: 'j i', displayname1: 'j i', displayname2: 'ij'},
      {alphasort: 'k, l', displayname: 'l k', displayname1: 'bar', displayname2: 'bats!'},
    ]
  end

  let(:expected) do
    [
      {alphasort: 'b, a', displayname: 'a b', displayname1: 'ab'},
      {alphasort: 'c, d', displayname: 'd c', displayname1: nil},
      {alphasort: 'e, f', displayname: 'f e', displayname1: nil},
      {alphasort: 'g, h', displayname: 'h g', displayname1: 'hg', displayname2: nil},
      {alphasort: 'i, j', displayname: 'j i', displayname1: nil, displayname2: 'ij'},
      {alphasort: 'k, l', displayname: 'l k', displayname1: 'bar', displayname2: 'bats!'},
    ]
  end
  
  it 'transforms as expected' do
    expect(result).to eq(expected)
  end
end
