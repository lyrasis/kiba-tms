# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Jobs::MultiTableMergeable::ReportableForTable do
  before(:each) do
    reset_configs
    clear_working
  end

  let(:base_prefix) { "MultiTableMergeable_ReportableForTable__" }

  context "when for objects" do
    let(:prefix) { "#{base_prefix}obj" }

    it "transforms as expected" do
      copy_from_test_to_working(
        "#{prefix}_src.csv", "alt_nums_for_objects.csv"
      )
      copy_from_test_to_working(
        "#{prefix}_lkup.csv", "objects_numbers_cleaned.csv"
      )
      setup_project
      result = result_path(:alt_nums_reportable_for__objects)
      expected = File.join(
        Tms.datadir, "test", "#{prefix}_dest.csv"
      )
      expect(result).to match_csv(expected)

      reset_configs
    end
  end

  context "when for constituents" do
    let(:prefix) { "#{base_prefix}con" }

    it "transforms as expected" do
      copy_from_test_to_working(
        "#{prefix}_src.csv", "alt_nums_for_constituents.csv"
      )
      copy_from_test_to_working(
        "#{prefix}_lkup.csv", "constituents_prepped_clean.csv"
      )
      setup_project
      result = result_path(:alt_nums_reportable_for__constituents)
      expected = File.join(
        Tms.datadir, "test", "#{prefix}_dest.csv"
      )
      expect(result).to match_csv(expected)

      reset_configs
    end
  end
end
