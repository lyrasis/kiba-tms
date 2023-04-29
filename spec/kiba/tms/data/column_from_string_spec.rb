# frozen_string_literal: true

require "spec_helper"

module Tms
  module UsedMod
    module_function

    def used?
      true
    end
  end
end

RSpec.describe Kiba::Tms::Data::ColumnFromString do
  subject(:klass) { described_class }

  describe ".call" do
    let(:col) { double("col") }
    let(:result) { klass.call(str: str, col: col) }

    context "with column in defined, used Module" do
      let(:str) { "UsedMod.title" }

      it "returns Data::Column" do
        allow(Tms).to receive(:configs).and_return([Tms::UsedMod])
        expect(col).to receive(:new) do |args|
          expect(args[:mod]).to eq("UsedMod")
          expect(args[:field]).to eq("title")
        end
        result
      end
    end
  end
end
