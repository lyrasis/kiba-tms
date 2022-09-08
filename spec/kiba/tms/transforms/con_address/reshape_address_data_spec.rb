# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Tms::Transforms::ConAddress::ReshapeAddressData do
  subject(:xform){ described_class.new }
  let(:result){ input.map{ |row| xform.process(row) } }
  let(:input) do
    [
      {displayname1: 'a', displayname2: 'b', streetline1: '1', streetline2: '2', streetline3: '3'},
      {displayname1: 'c', displayname2: '', streetline1: '4', streetline2: '5'},
      {displayname1: '', displayname2: 'd', streetline1: '', streetline2: '6'},
      {displayname1: '', displayname2: '', streetline1: '7', streetline2: '8', streetline3: '9'},
      {foo: 'bar'}
    ]
  end

  let(:expected) do
    [
      {addressplace1: 'a -- b', addressplace2: '1, 2, 3'},
      {addressplace1: 'c', addressplace2: '4, 5'},
      {addressplace1: 'd', addressplace2: '6'},
      {addressplace1: '7', addressplace2: '8, 9'},
      {addressplace1: nil, addressplace2: nil, foo: 'bar'}
    ]
  end
  
  it 'transforms as expected' do
    expect(result).to eq(expected)
  end
end
