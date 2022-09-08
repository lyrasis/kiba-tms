# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Tms::Transforms::Constituents::CleanRedundantOrgNameDetails do
  before(:all){ Tms::Constituents.config.preferred_name_field = :displayname }
  after(:all){ Tms::Constituents.reset_config }
  
  subject(:xform){ described_class.new }
  let(:result){ xform.process(row.dup) }

  context 'when not Organization' do
    let(:row){ {constituenttype: nil, displayname: 'foo', lastname: 'foo', } }

    it 'returns row unchanged' do
      expect(result).to eq(row)
    end
  end

  context 'when Organization and non-redundant name parts' do
    let(:row) do
      {
        constituenttype: 'Organization',
        displayname: 'John Doe & Associates',
        lastname: 'John Doe Associates'}
    end

    it 'returns row unchanged' do
      expect(result).to eq(row)
    end
  end

  context 'when Organization and redundant name parts' do
    let(:row) do
      {
        constituenttype: 'Organization',
        displayname: 'Moe Press, Inc.',
        firstname: 'Inc',
        lastname: 'Moe Press'}
    end
    let(:expected) do
      {
        constituenttype: 'Organization',
        displayname: 'Moe Press, Inc.',
        firstname: nil,
        lastname: nil}
    end

    it 'returns cleaned row' do
      expect(result).to eq(expected)
    end
  end

  context 'when Organization and only some name parts are redundant' do
    let(:row) do
      {
        constituenttype: 'Organization',
        displayname: 'Moe Press, Inc.',
        firstname: 'Incorporated',
        lastname: 'Moe Press'}
    end

    it 'returns original row' do
      expect(result).to eq(row)
    end
  end

  context 'when Organization and redundant name parts but position populated' do
    let(:row) do
      {
        constituenttype: 'Organization',
        displayname: 'Jane Doe Art',
        firstname: 'Jane',
        lastname: 'Doe',
        position: 'owner'
      }
    end
    it 'returns unchanged row' do
      expect(result).to eq(row)
    end
  end

end
