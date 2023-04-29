# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Data::ColumnFromString do
  subject(:klass) { described_class }

  module Tms
    module UnusedMod
      module_function

      def used?
        false
      end
    end

    module UsedMod
      module_function

      def used?
        true
      end
    end
  end

  describe ".call" do
    let(:result) { klass.call(str: str) }

    context "with column in defined, used Module" do
      let(:str) { "UsedMod.title" }

      it "returns Data::Column" do
        expect(result).to be_a(Tms::Data::Column)
      end
    end
  end
end
