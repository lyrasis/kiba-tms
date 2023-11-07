# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Layout/LineLength
RSpec.describe Kiba::Tms::Transforms::ThesXrefs::ForConstituentsTreatmentMergerTypeLabeledNote do
  # rubocop:enable Layout/LineLength

  subject { described_class.new }

  describe "#process" do
    let(:suffix) { "misc" }
    let(:type) { "internal" }
    let(:result) do
      subject.process(row, mergerow, suffix: suffix, type: type)
    end

    context "when no target value" do
      let(:row) { {} }

      context "with non-omitted term" do
        let(:mergerow) { {thesxreftype: "a", termused: "b", remarks: "c"} }
        let(:expected) { {term_internal_note_misc: "a: b -- c"} }

        it "returns expected row" do
          expect(result).to eq(expected)
        end
      end

      context "with omitted term" do
        let(:mergerow) { {thesxreftype: "a", termused: "b", remarks: "c"} }
        let(:expected) { {term_internal_note_misc: "a: c"} }

        it "returns expected row" do
          Tms::ThesXrefs.constituents_omit_terms << "b"
          expect(result).to eq(expected)
        end
      end
    end

    context "when existing target value" do
      let(:row) { {term_internal_note_misc: "a: b -- c"} }

      let(:mergerow) { {thesxreftype: "d", termused: "e", remarks: "f"} }
      let(:expected) do
        {term_internal_note_misc: "a: b -- c#{Tms.notedelim}d: e -- f"}
      end

      it "returns expected row" do
        expect(result).to eq(expected)
      end
    end
  end
end
