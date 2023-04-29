# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::ConDates::DateFromDatedescRemarkCombination do
  subject(:xform){ described_class.new }

  describe "#process" do
    let(:results){ rows.map{ |row| xform.process(row) } }
    
    let(:rows) do
      [
        {datedescription: "birth", remarks: "born 1939", date: nil}
      ]
    end
    let(:expected) do
      [
        {datedescription: "birth", remarks: nil, date: "1939"}
      ]
    end

    it "returns as expected" do
      expect(results).to eq(expected)
    end
  end
end
