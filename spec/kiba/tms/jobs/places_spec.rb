# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Jobs::Places do
  context "when no cleanup done", :initial do
    it "transforms as expected" do
      reset_configs
      clear_working
      copy_from_test_to_working("places_norm_unique_N0.csv")
      Tms::Places.config.returned = []
      Tms::Places.config.worksheets = []
      setup_project

      result_a = result_path(:places__norm_unique_cleaned)
      expected_a = File.join(
        Tms.datadir, "test", "places_norm_unique_cleaned_N0.csv"
      )

      result_b = result_path(:places__cleaned_unique)
      expected_b = File.join(
        Tms.datadir, "test", "places_cleaned_unique_N0.csv"
      )

      result_c = result_path(:places__worksheet)
      expected_c = File.join(
        Tms.datadir, "to_client", "places_worksheet_N1.csv"
      )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)

      FileUtils.rm(result_c)
      reset_configs
    end
  end

  context "when initial cleanup returned", :clean1 do
    it "transforms as expected" do
      reset_configs
      clear_working
      copy_from_test_to_working("places_norm_unique_N0.csv")
      Tms::Places.config.returned = [
        "places_worksheet_ret_N1.csv"
      ]
      Tms::Places.config.worksheets = [
        "places_worksheet_N1.csv"
      ]
      setup_project

      result_a = result_path(:places__returned_compile)
      expected_a = File.join(
        Tms.datadir, "test", "places_returned_compile_N1.csv"
      )

      result_b = result_path(:places__corrections)
      expected_b = File.join(
        Tms.datadir, "test", "places_corrections_N1.csv"
      )

      result_c = result_path(:places__norm_unique_cleaned)
      expected_c = File.join(
        Tms.datadir, "test", "places_norm_unique_cleaned_N1.csv"
      )

      result_d = result_path(:places__cleaned_unique)
      expected_d = File.join(
        Tms.datadir, "test", "places_cleaned_unique_N1.csv"
      )

      result_e = result_path(:places__worksheet)
      expected_e = File.join(
        Tms.datadir, "to_client", "places_worksheet_N2.csv"
      )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)
      expect(result_d).to match_csv(expected_d)
      expect(result_e).to match_csv(expected_e)

      FileUtils.rm(result_e)
      reset_configs
    end
  end

  context "when fresh data after initial cleanup", :fresh1 do
    it "transforms as expected" do
      reset_configs
      clear_working
      copy_from_test_to_working("places_orig_normalized_N2.csv")
      Tms::Places.config.returned = [
        "places_worksheet_ret_N1.csv"
      ]
      Tms::Places.config.worksheets = [
        "places_worksheet_N1.csv"
      ]
      setup_project

      result_a = result_path(:places__norm_unique)
      expected_a = File.join(
        Tms.datadir, "test", "places_norm_unique_N2.csv"
      )

      # :places__returned_compile should be identical to :clean1
      # :places__corrections should be identical to :clean1

      result_b = result_path(:places__norm_unique_cleaned)
      expected_b = File.join(
        Tms.datadir, "test", "places_norm_unique_cleaned_N2.csv"
      )

      result_c = result_path(:places__cleaned_unique)
      expected_c = File.join(
        Tms.datadir, "test", "places_cleaned_unique_N2.csv"
      )

      result_d = result_path(:places__worksheet)
      expected_d = File.join(
        Tms.datadir, "to_client", "places_worksheet_N3.csv"
      )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)
      expect(result_d).to match_csv(expected_d)

      FileUtils.rm(result_d)
      reset_configs
    end
  end

  context "when second round of cleanup", :clean2 do
    it "transforms as expected" do
      reset_configs
      clear_working
      copy_from_test_to_working("places_orig_normalized_N2.csv")
      Tms::Places.config.returned = [
        "places_worksheet_ret_N1.csv",
        "places_worksheet_ret_N3.csv"
      ]
      Tms::Places.config.worksheets = [
        "places_worksheet_N1.csv"
      ]
      setup_project

      result_a = result_path(:places__norm_unique)
      expected_a = File.join(
        Tms.datadir, "test", "places_norm_unique_N2.csv"
      )

      result_b = result_path(:places__returned_compile)
      expected_b = File.join(
        Tms.datadir, "test", "places_returned_compile_N3.csv"
      )

      result_c = result_path(:places__corrections)
      expected_c = File.join(
        Tms.datadir, "test", "places_corrections_N3.csv"
      )

      result_d = result_path(:places__norm_unique_cleaned)
      expected_d = File.join(
        Tms.datadir, "test", "places_norm_unique_cleaned_N3.csv"
      )

      result_e = result_path(:places__cleaned_unique)
      expected_e = File.join(
        Tms.datadir, "test", "places_cleaned_unique_N3.csv"
      )

      # result_d = result_path(:places__worksheet)
      # expected_d = File.join(
      #   Tms.datadir, "to_client", "places_worksheet_N3.csv"
      # )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)
      expect(result_d).to match_csv(expected_d)
      expect(result_e).to match_csv(expected_e)

      # FileUtils.rm(result_d)
      reset_configs
    end
  end
end
