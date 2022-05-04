# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Tms::Transforms::ConAddress::AddRetentionFlag do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }
  let(:transforms) do
    Kiba.job_segment do
      transform Kiba::Tms::Transforms::ConAddress::AddRetentionFlag
    end
  end
  let(:input) do
    [
      {matches_constituent: '1', streetline1: '1', active: '1'},
      {matches_constituent: '1', streetline1: '1', active: '0'},
      {matches_constituent: '', streetline1: '1', active: '1'},
      {matches_constituent: '1', streetline1: '', active: '1'},
      {foo: 'bar'}
    ]
  end

  context 'without omit_inactive' do
    let(:expected) do
      [
      {matches_constituent: '1', streetline1: '1', active: '1', keeping: 'y'},
      {matches_constituent: '1', streetline1: '1', active: '0', keeping: 'y'},
      {matches_constituent: '', streetline1: '1', active: '1', keeping: 'n - associated constituent not migrating'},
      {matches_constituent: '1', streetline1: '', active: '1', keeping: 'n - no address data in row'},
      {foo: 'bar', keeping: 'n - associated constituent not migrating'}
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'with omit_inactive' do
    before(:all){ Tms.config.constituents.omit_inactive_address = true }
    after(:all){ Tms.config.constituents.omit_inactive_address = false }
    let(:expected) do
      [
      {matches_constituent: '1', streetline1: '1', active: '1', keeping: 'y'},
      {matches_constituent: '1', streetline1: '1', active: '0', keeping: 'n - inactive address'},
      {matches_constituent: '', streetline1: '1', active: '1', keeping: 'n - associated constituent not migrating'},
      {matches_constituent: '1', streetline1: '', active: '1', keeping: 'n - no address data in row'},
      {foo: 'bar', keeping: 'n - associated constituent not migrating'}
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end
end
