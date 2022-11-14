# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Tms::Transforms::ObjLocations::AddFulllocid do
  module Tms::ObjLocations
    enable_test_interface
  end
  after(:each){ Tms::ObjLocations.reset_config }

  subject(:xform){ described_class.new }
  let(:result){ input.map{ |row| xform.process(row)[:fulllocid] } }

  context 'without temptext mapping done' do
    before(:each) do
      Kiba::Tms::ObjLocations.config.temptext_mapping_done = false
      Kiba::Tms::ObjLocations.config.fulllocid_fields = %i[temptext sublevel]
    end
    let(:input) do
      [
        {locationid: '1', temptext: 'foo', sublevel: 'bar'},
        {locationid: '1', temptext: nil, sublevel: ''}
      ]
    end

    let(:expected) do
      [
        '1|foo|bar',
        '1|nil|nil'
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'with temptext mapping done' do
    before(:each) do
      Kiba::Tms::ObjLocations.config.temptext_mapping_done = true
      Kiba::Tms::ObjLocations.config.fulllocid_fields = %i[temptext sublevel]
      Kiba::Tms::ObjLocations.config.temptext_target_fields =
        %i[loc2]
    end
    let(:input) do
      [
        {locationid: '1', temptext: 'foo', sublevel: 'bar',
         movementnote: 'foo', loc2: nil},
        {locationid: '1', temptext: 'foo', sublevel: 'bar',
         movementnote: nil, loc2: 'foo'},
        {locationid: '1', temptext: 'foo', sublevel: 'bar',
         movementnote: nil, loc2: 'baz'},
        {locationid: '1', temptext: nil, sublevel: '',
         movementnote: nil, loc2: nil}
      ]
    end

    let(:expected) do
      [
        '1|nil|bar',
        '1|baz|bar',
        '1|foo|bar',
        '1|nil|nil'
      ]
    end

    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end
end
