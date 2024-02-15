# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module ReferenceMaster
        module_function

        # @todo Create generalizable place/organization extraction
        def register
          Tms.registry.namespace("reference_master") do
            register :prep_clean, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::PrepClean,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_prep_clean.csv"),
              desc: "Merges in corrections from placepublished cleanup "\
                "worksheet, and headings worksheet if completed.",
              tags: %i[reference_master],
              lookup_on: :referenceid
            }
            register :journal_lookup, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::JournalLookup,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_journal_lookup.csv"),
              tags: %i[reference_master],
              lookup_on: :title
            }
            register :series_lookup, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::SeriesLookup,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_series_lookup.csv"),
              tags: %i[reference_master],
              lookup_on: :title
            }
            register :journals, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::Journals,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_journals.csv"),
              desc: "Extract journal field values to create Citation "\
                "authorities from",
              tags: %i[reference_master]
            }
            register :series, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::Series,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_series.csv"),
              desc: "Extract series field values to create Citation "\
                "authorities from",
              tags: %i[reference_master]
            }
            register :pubplace_cleaned, {
              path: File.join(Kiba::Tms.datadir, "supplied",
                "reference_master_placepublished_cleanup_2024-01-30.csv"),
              supplied: true,
              tags: %i[reference_master places orgs cleanup]
            }
            register :pubplace_cleaned_lkup, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::PubplaceCleanedLkup,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_pubplace_cleaned.csv"),
              tags: %i[reference_master places orgs cleanup]
            }
            register :places, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::Places,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_places.csv"),
              desc: "Extracts unique place values from placepublished, in "\
                "format for combination with other places for cleanup and "\
                "translation to authority terms",
              tags: %i[reference_master places]
            }
            register :place_authority_merge, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::PlaceAuthorityMerge,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_place_authority_merge.csv"),
              desc: "Merges in cleaned-up authority terms.",
              tags: %i[reference_master places],
              lookup_on: :placepublished
            }
            register :places_finalized, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::PlacesFinalized,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_places_finalized.csv"),
              desc: "Use for input for main citations ingest job",
              tags: %i[reference_master places]
            }
            register :xref_lkup, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::XrefLkup,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_xref_lkup.csv"),
              tags: %i[reference_master],
              lookup_on: :referenceid,
              desc: "Used to merge headings into RefXRefs"
            }

            register :date_base, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::DateBase,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_date_base.csv"),
              tags: %i[reference_master dates],
              desc: "Rows representing kept citation records, which have "\
                "date populated"
            }
            register :date_uniq, {
              creator: Kiba::Tms::Jobs::ReferenceMaster::DateUniq,
              path: File.join(Kiba::Tms.datadir, "working",
                "reference_master_date_uniq.csv"),
              tags: %i[reference_master dates],
              desc: "Unique date values for Emendate translation"
            }

            if Tms::ReferenceMaster.headings_needed
              register :headings_worksheet, {
                creator:
                Tms::Jobs::ReferenceMaster::HeadingsWorksheet,
                path: File.join(Kiba::Tms.datadir, "to_client",
                  "reference_master_headings.csv"),
                desc: "Supports manual provision of unique headings",
                tags: %i[reference_master],
                dest_special_opts: {
                  initial_headers: %i[heading duplicate title subtitle
                    displaydate]
                }
              }
              register :headings_returned, {
                supplied: true,
                path: File.join(Kiba::Tms.datadir, "supplied",
                  "reference_master_headings.csv"),
                desc: "Manual indication of unique heading values, or if "\
                  "are duplicates, which to drop when creating authorities",
                tags: %i[reference_master],
                lookup_on: :referenceid
              }
            end

            # if Tms::ReferenceMaster.placepublished_done
            #   Tms::ReferenceMaster.placepublished_worksheet_jobs
            #     .each_with_index do |job, idx|
            #       jobname = job.to_s
            #         .delete_prefix("reference_master__")
            #         .to_sym
            #       register jobname, {
            #         path: Tms::ReferenceMaster.placepublished_worksheets[idx],
            #         desc: "Placepublished cleanup worksheet provided to client",
            #         tags: %i[reference_master cleanup],
            #         supplied: true
            #       }
            #     end
            #   register :placepublished_worksheet_compile, {
            #     creator:
            #     Tms::Jobs::ReferenceMaster::PlacepublishedWorksheetCompile,
            #     path: File.join(
            #       Kiba::Tms.datadir,
            #       "working",
            #       "reference_master_placepublished_worksheet_compile.csv"
            #     ),
            #     tags: %i[reference_master cleanup],
            #     desc: "Joins completed supplied worksheets and deduplicates "\
            #       "on :merge_fingerprint",
            #     lookup_on: :merge_fingerprint
            #   }
            #   Tms::ReferenceMaster.placepublished_returned_jobs
            #     .each_with_index do |job, idx|
            #       jobname = job.to_s
            #         .delete_prefix("reference_master__")
            #         .to_sym
            #       register jobname, {
            #         path: Tms::ReferenceMaster.placepublished_returned[idx],
            #         desc: "Completed placepublished cleanup worksheet",
            #         tags: %i[reference_master cleanup],
            #         supplied: true
            #       }
            #     end
            #   register :placepublished_returned_compile, {
            #     creator:
            #     Kiba::Tms::Jobs::ReferenceMaster::PlacepublishedReturnedCompile,
            #     path: File.join(
            #       Kiba::Tms.datadir,
            #       "working",
            #       "reference_master_placepublished_returned_compile.csv"
            #     ),
            #     tags: %i[reference_master cleanup],
            #     desc: "Joins completed worksheets and deduplicates on "\
            #       ":merge_fingerprint. Flags corrected fields (based on "\
            #       "decoded fingerprint) and deletes the decoded original "\
            #       "fields",
            #     lookup_on: :merge_fingerprint
            #   }
            #   register :placepublished_corrections, {
            #     creator:
            #     Kiba::Tms::Jobs::ReferenceMaster::PlacepublishedCorrections,
            #     path: File.join(
            #       Kiba::Tms.datadir,
            #       "working",
            #       "reference_master_placepublished_corrections.csv"
            #     ),
            #     tags: %i[reference_master cleanup],
            #     desc: "Only rows from :placepublished_returned_compile that "\
            #       "have changes, for merge into :placepublishedcleaned.",
            #     lookup_on: :merge_fingerprint
            #   }
            # end
          end
        end
      end
    end
  end
end
