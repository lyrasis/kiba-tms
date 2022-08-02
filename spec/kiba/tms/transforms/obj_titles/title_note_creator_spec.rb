# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Tms::Transforms::ObjTitles::TitleNoteCreator do
  subject(:xform){ described_class.new }
  let(:result){ input.map{ |row| xform.process(row) } }
  
  let(:input) do
    [
      {remarks: nil,  dateeffectiveisodate: nil, titletype: nil, title: nil},
      {remarks: 'remark',  dateeffectiveisodate: '1982', titletype: 'former', title: 'blah'},
      {remarks: nil,  dateeffectiveisodate: '1982', titletype: 'former', title: 'blah'},
      {remarks: 'remark',  dateeffectiveisodate: '1982', titletype: nil, title: 'blah'},
      {remarks: nil,  dateeffectiveisodate: '1982', titletype: nil, title: 'blah'},
    ]
  end

  let(:expected) do
    [
      {titletype: nil, title: nil, titlenote: nil},
      {titletype: 'former', title: 'blah',
       titlenote: 'Note for former title (blah): remark; Title effective: 1982'},
      {titletype: 'former', title: 'blah',
       titlenote: 'Former title (blah) effective: 1982'},
      {titletype: nil, title: 'blah',
       titlenote: 'Note for title (blah): remark; Title effective: 1982'},
      {titletype: nil, title: 'blah',
       titlenote: 'Title (blah) effective: 1982'},
    ]
  end
  
  it 'transforms as expected' do
    expect(result).to eq(expected)
  end
end
