# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Layout/LineLength
RSpec.describe Kiba::Tms::Transforms::ThesXrefs::ForConstituentsTreatmentMergerNationality do
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
            term_nationality_label: "a",
            term_nationality: "b",
            term_nationality_note: "%NULLVALUE%"
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
          term_nationality_label: "a",
          term_nationality: "b",
          term_nationality_note: "%NULLVALUE%"
        }
      end

      context "with term only" do
        let(:mergerow) { {thesxreftype: "c", termused: "d", remarks: "e"} }
        let(:expected) do
          {
            term_nationality_label: "a|c",
            term_nationality: "b|d",
            term_nationality_note: "%NULLVALUE%|e"
          }
        end

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end
    end
  end
end
