# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Layout/LineLength
RSpec.describe Kiba::Tms::Transforms::ThesXrefs::ForConstituentsPostProcessorNationality do
  # rubocop:enable Layout/LineLength

  subject { described_class.new(authtype: authtype) }

  describe "#process" do
    let(:result) { subject.process(row) }

    context "when authtype = :person" do
      let(:authtype) { :person }

      context "with no term" do
        let(:row) { {} }
        let(:expected) { {term_note_nationality: nil} }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end

      context "when not main field source" do
        let(:row) {
          {
            nationality: "z",
            term_nationality: "a|b",
            term_nationality_label: "c|d",
            term_nationality_note: "%NULLVALUE%|e"
          }
        }
        let(:expected) {
          {
            nationality: "z",
            term_note_nationality: "C note: a#{Tms.notedelim}D note: b -- e"
          }
        }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end

      context "when main field source, multivalued" do
        let(:row) {
          {
            term_nationality: "a|b",
            term_nationality_label: "c|d",
            term_nationality_note: "e|%NULLVALUE%"
          }
        }
        let(:expected) {
          {
            nationality: "a -- e",
            term_note_nationality: "D note: b"
          }
        }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end

      context "when main field source, single-valued" do
        let(:row) {
          {
            term_nationality: "a",
            term_nationality_label: "c",
            term_nationality_note: "%NULLVALUE%"
          }
        }
        let(:expected) {
          {
            nationality: "a",
            term_note_nationality: nil
          }
        }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end
    end

    context "when authtype = :org" do
      let(:authtype) { :org }

      context "with no term" do
        let(:row) { {} }
        let(:expected) { {term_note_nationality: nil} }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end

      context "with multi terms" do
        let(:row) {
          {
            term_nationality: "a|b",
            term_nationality_label: "c|d",
            term_nationality_note: "%NULLVALUE%|e"
          }
        }
        let(:expected) {
          {
            term_note_nationality: "C note: a#{Tms.notedelim}D note: b -- e"
          }
        }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end
    end
  end
end
