# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Layout/LineLength
RSpec.describe Kiba::Tms::Transforms::ThesXrefs::ForConstituentsPostProcessorGender do
  # rubocop:enable Layout/LineLength

  subject { described_class.new(authtype: authtype) }

  describe "#process" do
    let(:result) { subject.process(row) }

    context "when authtype = :person" do
      let(:authtype) { :person }
      let(:blankrow) do
        {
          gender: nil,
          term_note_gender: nil
        }
      end

      context "with no term" do
        let(:row) { {} }
        let(:expected) { blankrow }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end

      context "multivalued" do
        let(:row) {
          {
            term_gender: "a|b|c",
            term_gender_label: "c|d|e",
            term_gender_note: "f|%NULLVALUE%|g"
          }
        }
        let(:expected) {
          {
            gender: "c",
            term_note_gender: "C note: a -- f#{Tms.notedelim}"\
              "D note: b#{Tms.notedelim}"\
              "E note on Gender field value: g"
          }
        }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end

      context "when single-valued without note" do
        let(:row) {
          {
            term_gender: "a",
            term_gender_label: "c",
            term_gender_note: "%NULLVALUE%"
          }
        }
        let(:expected) {
          {
            gender: "a",
            term_note_gender: nil
          }
        }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end

      context "when single-valued with note" do
        let(:row) {
          {
            term_gender: "a",
            term_gender_label: "c",
            term_gender_note: "b"
          }
        }
        let(:expected) {
          {
            gender: "a",
            term_note_gender: "C note on Gender field value: b"
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
        let(:expected) { {term_note_gender: nil} }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end

      context "with multi terms" do
        let(:row) {
          {
            term_gender: "a|b",
            term_gender_label: "c|d",
            term_gender_note: "%NULLVALUE%|e"
          }
        }
        let(:expected) {
          {
            term_note_gender: "C note: a#{Tms.notedelim}"\
              "D note: b -- e"
          }
        }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end
    end
  end
end
