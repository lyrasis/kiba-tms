# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Mixins::ReportableForTable do
  before(:each) do
    reset_configs
    clear_working
  end

  context "when no cleanup done", :initial do
    it "transforms as expected" do
      copy_from_test("rftc0_alt_nums_reportable_for__objects.csv",
        "alt_nums_reportable_for__objects.csv")
      Tms::AltNums.config.target_table_empty_type_cleanup_needed = [
        "Objects"
      ]
      Tms::AltNums.config.target_table_type_cleanup_needed = [
        "Objects"
      ]
      setup_project

      # Prepare base for empty type cleanup
      result_a = result_path(:alt_nums_reportable_for__objects_no_type)
      expected_a = File.join(
        Tms.datadir, "test",
        "rftc0_alt_nums_reportable_for__objects_no_type.csv"
      )
      expect(result_a).to match_csv(expected_a)

      # With no cleanup, original alt_nums_reportable_for__objects.csv is
      #   passed through
      result_b = result_path(
        :alt_nums_reportable_for__objects_empty_type_cleanup_merge
      )
      expected_b = File.join(
        Tms.datadir, "test",
        "rftc0_alt_nums_reportable_for__objects.csv"
      )
      expect(result_b).to match_csv(expected_b)

      # Prepare base for type cleanup
      result_c = result_path(
        :alt_nums_reportable_for__objects_type_occs
      )
      expected_c = File.join(
        Tms.datadir, "test",
        "rftc0_alt_nums_reportable_for__objects_type_occs.csv"
      )
      expect(result_c).to match_csv(expected_c)

      # Cleanup final has no mergeable cleanup data (correct_type,
      #   treatment, and note are blank)
      result_d = result_path(
        :alt_nums_for_objects_type_cleanup__final
      )
      expected_d = File.join(
        Tms.datadir, "test",
        "rftc0_alt_nums_for_objects_type_cleanup__final.csv"
      )
      expect(result_d).to match_csv(expected_d)

      # With no cleanup, original alt_nums_reportable_for__objects.csv
      #   is passed through
      result_e = result_path(
        :alt_nums_reportable_for__objects_type_cleanup_merge
      )
      expected_e = File.join(
        Tms.datadir, "test",
        "rftc0_alt_nums_reportable_for__objects_type_cleanup_merge.csv"
      )
      expect(result_e).to match_csv(expected_e)

      # Both worksheets are as expected
      result_f = result_path(
        :alt_nums_for_objects_empty_type_cleanup__worksheet
      )
      expected_f = File.join(
        Tms.datadir, "test",
        "rftc0_alt_nums_for_objects_empty_type_cleanup_worksheet.csv"
      )
      expect(result_f).to match_csv(expected_f)

      result_g = result_path(
        :alt_nums_for_objects_type_cleanup__worksheet
      )
      expected_g = File.join(
        Tms.datadir, "test",
        "rftc0_alt_nums_for_objects_type_cleanup_worksheet.csv"
      )
      expect(result_g).to match_csv(expected_g)
    end
  end

  context "when initial type cleanup done", :initial_type do
    it "transforms as expected" do
      copy_from_test("rftc0_alt_nums_reportable_for__objects.csv",
        "alt_nums_reportable_for__objects.csv")
      Tms::AltNums.config.target_table_empty_type_cleanup_needed = [
        "Objects"
      ]
      Tms::AltNums.config.target_table_type_cleanup_needed = [
        "Objects"
      ]
      dependent_config = <<~CFG
        Kiba::Tms::AltNumsForObjectsTypeCleanup.config.provided_worksheets = [
                "alt_nums_for_objects_type_cleanup_worksheet_N0.csv"
              ]
              Kiba::Tms::AltNumsForObjectsTypeCleanup.config.returned_files = [
                "alt_nums_for_objects_type_cleanup_worksheet_N1.csv"
              ]
      CFG
      setup_project(dependent_config)

      type_cleanup_final = result_path(
        :alt_nums_for_objects_type_cleanup__final
      )
      expected_type_cleanup_final = File.join(
        Tms.datadir, "test",
        "rftc1_alt_nums_for_objects_type_cleanup_final.csv"
      )
      expect(type_cleanup_final).to match_csv(expected_type_cleanup_final)

      result_e = result_path(
        :alt_nums_reportable_for__objects_type_cleanup_merge
      )
      expected_e = File.join(
        Tms.datadir, "test",
        "rftc1_alt_nums_reportable_for__objects_type_cleanup_merge.csv"
      )
      expect(result_e).to match_csv(expected_e)
    end
  end

  context "when empty type cleanup done after type cleanup" do
    it "transforms as expected" do
      copy_from_test("rftc0_alt_nums_reportable_for__objects.csv",
        "alt_nums_reportable_for__objects.csv")
      Tms::AltNums.config.target_table_empty_type_cleanup_needed = [
        "Objects"
      ]
      Tms::AltNums.config.target_table_type_cleanup_needed = [
        "Objects"
      ]
      dependent_config = <<~CFG
        Kiba::Tms::AltNumsForObjectsTypeCleanup.config.provided_worksheets = [
                "alt_nums_for_objects_type_cleanup_worksheet_N0.csv"
              ]
        Kiba::Tms::AltNumsForObjectsTypeCleanup.config.returned_files = [
          "alt_nums_for_objects_type_cleanup_worksheet_N1.csv"
        ]
        Kiba::Tms::AltNumsForObjectsEmptyTypeCleanup.config.provided_worksheets = [
                "alt_nums_for_objects_empty_type_cleanup_worksheet_N0.csv"
              ]
        Kiba::Tms::AltNumsForObjectsEmptyTypeCleanup.config.returned_files = [
          "alt_nums_for_objects_empty_type_cleanup_worksheet_N2.csv"
        ]
      CFG
      setup_project(dependent_config)

      # With no cleanup, original alt_nums_reportable_for__objects.csv is
      #   passed through
      empty_type_clean_merge = result_path(
        :alt_nums_reportable_for__objects_empty_type_cleanup_merge
      )
      expected_empty_type_clean_merge = File.join(
        Tms.datadir, "test",
        "rftc2_alt_nums_reportable_for__objects_empty_type_cleanup_merge.csv"
      )
      expect(empty_type_clean_merge).to match_csv(
        expected_empty_type_clean_merge
      )

      # Prepare base for type cleanup
      type_occs = result_path(
        :alt_nums_reportable_for__objects_type_occs
      )
      expected_type_occs = File.join(
        Tms.datadir, "test",
        "rftc2_alt_nums_reportable_for__objects_type_occs.csv"
      )
      expect(type_occs).to match_csv(expected_type_occs)

      type_cleanup_worksheet = result_path(
        :alt_nums_for_objects_type_cleanup__worksheet
      )
      expected_type_cleanup_worksheet = File.join(
        Tms.datadir, "to_client",
        "alt_nums_for_objects_type_cleanup_worksheet_N2.csv"
      )
      expect(type_cleanup_worksheet).to match_csv(
        expected_type_cleanup_worksheet
      )
    end
  end

  context "when final type cleanup done" do
    it "transforms as expected" do
      copy_from_test("rftc0_alt_nums_reportable_for__objects.csv",
        "alt_nums_reportable_for__objects.csv")
      Tms::AltNums.config.target_table_empty_type_cleanup_needed = [
        "Objects"
      ]
      Tms::AltNums.config.target_table_type_cleanup_needed = [
        "Objects"
      ]
      dependent_config = <<~CFG
        Kiba::Tms::AltNumsForObjectsTypeCleanup.config.provided_worksheets = [
                "alt_nums_for_objects_type_cleanup_worksheet_N0.csv",
                "alt_nums_for_objects_type_cleanup_worksheet_N2.csv"
        ]
        Kiba::Tms::AltNumsForObjectsTypeCleanup.config.returned_files = [
          "alt_nums_for_objects_type_cleanup_worksheet_N1.csv",
          "alt_nums_for_objects_type_cleanup_worksheet_N3.csv"
        ]
        Kiba::Tms::AltNumsForObjectsEmptyTypeCleanup.config.provided_worksheets = [
                "alt_nums_for_objects_empty_type_cleanup_worksheet_N0.csv"
              ]
        Kiba::Tms::AltNumsForObjectsEmptyTypeCleanup.config.returned_files = [
          "alt_nums_for_objects_empty_type_cleanup_worksheet_N2.csv"
        ]
      CFG
      setup_project(dependent_config)

      result_e = result_path(
        :alt_nums_reportable_for__objects_type_cleanup_merge
      )
      expected_e = File.join(
        Tms.datadir, "test",
        "rftc3_alt_nums_reportable_for__objects_type_cleanup_merge.csv"
      )
      expect(result_e).to match_csv(expected_e)
    end
  end
end
