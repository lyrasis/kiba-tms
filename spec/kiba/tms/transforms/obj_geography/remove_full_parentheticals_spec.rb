# frozen_string_literal: true

RSpec.describe Kiba::Tms::Transforms::ObjGeography::RemoveFullParentheticals do
  subject(:xform) { described_class.new(**params) }
  let(:params) { {fields: %i[city state]} }
  let(:row) { {city: "(New York)", state: "NY (state)"} }

  describe "#process" do
    let(:result) { xform.process(row) }

    it "transforms as expected" do
      expected = {city: "New York", state: "NY (state)"}
      expect(result).to eq(expected)
    end
  end
end
