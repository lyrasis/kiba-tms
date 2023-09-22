# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::AltNums::ForObjectsMerger do
  subject(:xform) { described_class.new }

  before(:all) do
    copy_from_test(
      "TransformsAltNumsForObjectsMerger.csv",
      "alt_nums_reportable_for__objects_type_cleanup_merge.csv"
    )
    setup_project
  end

  describe "#lookup" do
    let(:result) { xform.send(:lookup) }

    it "is a hash" do
      expect(result).to be_a(Hash)
    end
  end

  describe "#treatments" do
    let(:result) { xform.send(:treatments) }

    it "prepares as expected" do
      expect(result).to be_a(Hash)
      expect(result.first[0]).to be_a(String)
    end
  end

  describe "#process" do
    let(:result) { xform.process(row) }

    context "when no matching merge rows" do
      let(:row) { {objectid: "nope"} }

      it "returns orig row" do
        expect(result).to eq(row)
      end
    end

    context "when merge row has no treatment" do
      let(:row) { {objectid: "1"} }

      it "merges with default treatment" do
        expected = {objectid: "1", othernumber_value: "2007.51|S-41B",
                    othernumber_type: "Accession lot|%NULLVALUE%"}
        expect(result).to eq(expected)
      end
    end

    context "when merge row treatment is numtyped_annotation" do
      let(:row) { {objectid: "2"} }

      it "merges with default treatment" do
        expected = {objectid: "2", altnum_annotationtype:
                    "numtype: Loan number|numtype: Loan number",
                    altnum_annotationnote:
                    "L99.4.30 (numtype note; A remark; 2016-07-08 -)|"\
                      "L2005.50.13 (2005-08-09 - 2005-09-10)"}
        expect(result).to eq(expected)
      end
    end

    context "when merge row treatment is altnum_annotation" do
      let(:row) { {objectid: "3"} }

      it "merges with default treatment" do
        expected = {objectid: "3", altnum_annotationtype:
                    "alternate number|alternate number",
                    altnum_annotationnote:
                    "6510200360 (Former number)|660807088 (Former number; "\
                   "another note; 2015-03-20 -)"}
        expect(result).to eq(expected)
      end
    end
  end
end
