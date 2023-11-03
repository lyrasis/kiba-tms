# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Layout/LineLength
RSpec.describe Kiba::Tms::Transforms::ThesXrefs::ForConstituentsTreatmentMergerGender do
  # rubocop:enable Layout/LineLength

  subject { described_class.new }

  describe "#process" do
    let(:result) { subject.process(row, mergerow) }

    context "when no target value" do
      let(:row) { {} }

      context "with term and remarks" do
        let(:mergerow) {
          {termpreferred: "b", remarks: "a", thesxreftype: "ca"}
        }
        let(:expected) { {term_gender: "b", term_gender_note: "Ca note: a"} }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end

      context "with term only" do
        let(:mergerow) { {termpreferred: "b", thesxreftype: "c"} }
        let(:expected) { {term_gender: "b"} }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end
    end

    context "when existing target value" do
      let(:row) { {term_gender: "b", term_gender_note: "foo"} }

      context "with term only" do
        let(:mergerow) { {termpreferred: "d", remarks: "e", thesxreftype: "f"} }
        let(:expected) do
          {
            term_gender: "b|d",
            term_gender_note: "foo%CR%%CR%F note: e"
          }
        end

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end
    end
  end
end
