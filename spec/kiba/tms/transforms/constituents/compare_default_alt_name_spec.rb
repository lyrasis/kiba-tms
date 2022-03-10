# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Tms::Transforms::Constituents::CompareDefaultAltName do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }
  let(:transforms) do
    Kiba.job_segment do
      transform Kiba::Tms::Transforms::Constituents::CompareDefaultAltName
    end
  end
  let(:input) do
    [
      {displayname: 'a', alt_displayname: 'a'},
      {displayname: 'a', alt_displayname: 'b'},
      {displayname: 'a', alt_displayname: 'A'},
      {displayname: 'a', alt_displayname: ''},
      {displayname: '', alt_displayname: 'a'},
      {displayname: '', alt_displayname: nil},
    ]
  end
  
    let(:expected) do
      [
        'y',
        'n',
        'y',
        'n',
        'n',
        'y'
      ]
    end
    
    it 'transforms as expected' do
      expect(result.map{ |row| row[:displayname_compare]}).to eq(expected)
    end
end
