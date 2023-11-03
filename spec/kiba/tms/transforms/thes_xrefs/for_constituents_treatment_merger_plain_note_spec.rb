# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Layout/LineLength
RSpec.describe Kiba::Tms::Transforms::ThesXrefs::ForConstituentsTreatmentMergerPlainNote do
  # rubocop:enable Layout/LineLength

  subject { described_class.new }

  describe "#process" do
    let(:result) { subject.process(row, mergerow) }

    context "when no target value" do
      let(:row) { {} }

      context "with term and remarks" do
        let(:mergerow) { {termused: "a", remarks: "b"} }

        it "returns expected row" do
          expect(result).to eq({term_plain_note: "Untyped note: a -- b"})
        end
      end

      context "with term only" do
        let(:mergerow) { {termused: "a"} }

        it "returns expected row" do
          expect(result).to eq({term_plain_note: "Untyped note: a"})
        end
      end
    end

    context "when existing target value" do
      let(:row) { {term_plain_note: "foo"} }

      context "with term only" do
        let(:mergerow) { {termused: "a"} }

        it "returns expected row" do
          expect(result).to eq({term_plain_note: "foo%CR%%CR%Untyped note: a"})
        end
      end
    end
  end
end
