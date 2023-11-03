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

      context "with null source" do
        let(:mergerow) { {thesxreftype: "a", termused: "b"} }
        let(:expected) do
          {
            term_gender_label: "a",
            term_gender: "b",
            term_gender_note: "%NULLVALUE%"
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
          term_gender_label: "a",
          term_gender: "b",
          term_gender_note: "%NULLVALUE%"
        }
      end

      context "with term only" do
        let(:mergerow) { {thesxreftype: "c", termused: "d", remarks: "e"} }
        let(:expected) do
          {
            term_gender_label: "a|c",
            term_gender: "b|d",
            term_gender_note: "%NULLVALUE%|e"
          }
        end

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end
    end
  end
end
