# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Layout/LineLength
RSpec.describe Kiba::Tms::Transforms::ThesXrefs::ForConstituentsTreatmentMergerBirthFoundingPlace do
  # rubocop:enable Layout/LineLength

  subject { described_class.new }

  describe "#process" do
    let(:result) { subject.process(row, mergerow) }

    context "when no target value" do
      let(:row) { {} }

      context "with null source" do
        let(:mergerow) { {termpreferred: "b", termused: "a"} }
        let(:expected) do
          {
            term_birth_founding_place_preferred: "b",
            term_birth_founding_place_used: "a",
            term_birth_founding_place_note: "%NULLVALUE%"
          }
        end

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end
    end

    context "when existing target value" do
      let(:row) do
        {
          term_birth_founding_place_preferred: "b",
          term_birth_founding_place_used: "a",
          term_birth_founding_place_note: "%NULLVALUE%"
        }
      end

      context "with term only" do
        let(:mergerow) { {termpreferred: "c", termused: "d", remarks: "e"} }
        let(:expected) do
          {
            term_birth_founding_place_preferred: "b|c",
            term_birth_founding_place_used: "a|d",
            term_birth_founding_place_note: "%NULLVALUE%|e"
          }
        end

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end
    end
  end
end
