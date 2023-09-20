# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::PlacesCleanupInitial do
  before(:each) do
    reset_configs
    clear_working
  end

  context "when no cleanup done", :initial do
    it "transforms as expected" do
      copy_from_test("places_norm_unique_N0.csv")
      Kiba::Tms::PlacesCleanupInitial.config.provided_worksheets = []
      Kiba::Tms::PlacesCleanupInitial.config.returned_files = []
      setup_project

      result_a = result_path(Tms::PlacesCleanupInitial.base_job_cleaned_job_key)
      expected_a = File.join(
        Tms.datadir, "test", "places_cleanup_initial_base_job_cleaned_N0.csv"
      )

      result_b = result_path(Tms::PlacesCleanupInitial.cleaned_uniq_job_key)
      expected_b = File.join(
        Tms.datadir, "test", "places_cleanup_initial_cleaned_uniq_N0.csv"
      )

      result_c = result_path(Tms::PlacesCleanupInitial.worksheet_job_key)
      expected_c = File.join(
        Tms.datadir, "to_client", "places_cleanup_initial_worksheet_N1.csv"
      )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)

      FileUtils.rm(result_c)
    end
  end

  context "when initial cleanup returned", :clean1 do
    it "transforms as expected" do
      copy_from_test("places_norm_unique_N0.csv")
      Tms::PlacesCleanupInitial.config.returned_files = [
        "places_cleanup_initial_worksheet_1.csv"
      ]
      Tms::PlacesCleanupInitial.config.provided_worksheets = [
        "places_cleanup_initial_worksheet_N1.csv"
      ]
      setup_project

      result_a = result_path(
        Tms::PlacesCleanupInitial.returned_compiled_job_key
      )
      expected_a = File.join(
        Tms.datadir, "test", "places_cleanup_initial_returned_compiled_N1.csv"
      )
      result_b = result_path(
        Tms::PlacesCleanupInitial.corrections_job_key
      )
      expected_b = File.join(
        Tms.datadir, "test", "places_cleanup_initial_corrections_N1.csv"
      )

      result_c = result_path(
        Tms::PlacesCleanupInitial.base_job_cleaned_job_key
      )
      expected_c = File.join(
        Tms.datadir, "test", "places_cleanup_initial_base_job_cleaned_N1.csv"
      )

      result_d = result_path(
        Tms::PlacesCleanupInitial.cleaned_uniq_job_key
      )
      expected_d = File.join(
        Tms.datadir, "test", "places_cleanup_initial_cleaned_uniq_N1.csv"
      )
      result_e = result_path(
        Tms::PlacesCleanupInitial.worksheet_job_key
      )
      expected_e = File.join(
        Tms.datadir, "to_client", "places_cleanup_initial_worksheet_N2.csv"
      )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)
      expect(result_d).to match_csv(expected_d)
      expect(result_e).to match_csv(expected_e)

      FileUtils.rm(result_e)
    end
  end

  context "when fresh data after initial cleanup", :fresh1 do
    it "transforms as expected" do
      copy_from_test("places_orig_normalized_N2.csv")
      Tms::PlacesCleanupInitial.config.returned_files = [
        "places_worksheet_ret_N1.csv"
      ]
      Tms::PlacesCleanupInitial.config.provided_worksheets = [
        "places_worksheet_N1.csv"
      ]
      setup_project

      result_a = result_path(:places__norm_unique)
      expected_a = File.join(
        Tms.datadir, "test", "places_norm_unique_N2.csv"
      )

      # :places__returned_compile should be identical to :clean1
      # :places__corrections should be identical to :clean1

      result_b = result_path(
        Tms::PlacesCleanupInitial.base_job_cleaned_job_key
      )
      expected_b = File.join(
        Tms.datadir, "test", "places_cleanup_initial_base_job_cleaned_N2.csv"
      )

      result_c = result_path(
        Tms::PlacesCleanupInitial.cleaned_uniq_job_key
      )
      expected_c = File.join(
        Tms.datadir, "test", "places_cleanup_initial_cleaned_uniq_N2.csv"
      )

      result_d = result_path(
        Tms::PlacesCleanupInitial.worksheet_job_key
      )
      expected_d = File.join(
        Tms.datadir, "to_client", "places_cleanup_initial_worksheet_N3.csv"
      )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)
      expect(result_d).to match_csv(expected_d)

      FileUtils.rm(result_d)
    end
  end

  context "when second round of cleanup", :clean2 do
    it "transforms as expected" do
      copy_from_test("places_orig_normalized_N2.csv")
      Tms::PlacesCleanupInitial.config.returned_files = [
        "places_cleanup_initial_worksheet_1.csv",
        "places_cleanup_initial_worksheet_3.csv"
      ]
      Tms::PlacesCleanupInitial.config.provided_worksheets = [
        "places_cleanup_initial_worksheet_N1.csv"
      ]
      setup_project

      result_a = result_path(:places__norm_unique)
      expected_a = File.join(
        Tms.datadir, "test", "places_norm_unique_N2.csv"
      )

      result_b = result_path(
        Tms::PlacesCleanupInitial.returned_compiled_job_key
      )
      expected_b = File.join(
        Tms.datadir, "test", "places_cleanup_initial_returned_compiled_N3.csv"
      )

      result_c = result_path(
        Tms::PlacesCleanupInitial.corrections_job_key
      )
      expected_c = File.join(
        Tms.datadir, "test", "places_cleanup_initial_corrections_N3.csv"
      )

      result_d = result_path(
        Tms::PlacesCleanupInitial.base_job_cleaned_job_key
      )
      expected_d = File.join(
        Tms.datadir, "test", "places_cleanup_initial_base_job_cleaned_N3.csv"
      )

      result_e = result_path(
        Tms::PlacesCleanupInitial.cleaned_uniq_job_key
      )
      expected_e = File.join(
        Tms.datadir, "test", "places_cleanup_initial_cleaned_uniq_N3.csv"
      )

      result_f = result_path(
        Tms::PlacesCleanupInitial.final_job_key
      )
      expected_f = File.join(
        Tms.datadir, "test", "places_cleanup_initial_final_N3.csv"
      )

      expect(result_a).to match_csv(expected_a)
      expect(result_b).to match_csv(expected_b)
      expect(result_c).to match_csv(expected_c)
      expect(result_d).to match_csv(expected_d)
      expect(result_e).to match_csv(expected_e)
      expect(result_f).to match_csv(expected_f)
    end
  end
end
