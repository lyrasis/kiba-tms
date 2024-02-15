# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module NameTypeCleanup
        module_function

        def register
          Kiba::Tms.registry.namespace("name_type_cleanup") do
            register :from_base_data, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::FromBaseData,
              path: File.join(Kiba::Tms.datadir, "working",
                "name_type_cleanup_from_base_data.csv"),
              desc: "Data from main/base data source used to create Name Type review/cleanup worksheet",
              tags: %i[names cleanup]
            }
            register :worksheet, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::Worksheet,
              path: File.join(
                Kiba::Tms.datadir,
                "to_client",
                "name_type_cleanup_worksheet.csv"
              ),
              tags: %i[names cleanup],
              dest_special_opts: {
                initial_headers: Tms::NameTypeCleanup.initial_headers
              }
            }
            # For use with :convert_returned_to_uncontrolled. Manually tweak if
            #   needed
            # register :worksheet_returned, {
            #   path: File.join(
            #     Kiba::Tms.datadir,
            #     'supplied',
            #     'name_type_cleanup_20221212.csv'
            #   ),
            #   supplied: true
            # }
            # # Manually tweak this one if you need to use it.
            # register :convert_returned_to_uncontrolled, {
            #   creator: Kiba::Tms::Jobs::NameTypeCleanup::ConvertReturnedToUncontrolled,
            #   path: File.join(
            #     Kiba::Tms.datadir,
            #     'supplied',
            #     'name_type_cleanup_20221212_CONVERTED.csv'
            #   ),
            #   tags: %i[names cleanup]
            # }

            if Tms::NameTypeCleanup.done
              Tms::NameTypeCleanup.provided_worksheet_jobs
                .each_with_index do |job, idx|
                  jobname = job.to_s
                    .delete_prefix("name_type_cleanup__")
                    .to_sym
                  register jobname, {
                    path: Tms::NameTypeCleanup.provided_worksheets[idx],
                    desc: "NameType cleanup worksheet provided to client",
                    tags: %i[names cleanup],
                    supplied: true
                  }
                end
              register :previous_worksheet_compile, {
                creator:
                Kiba::Tms::Jobs::NameTypeCleanup::PreviousWorksheetCompile,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "name_type_cleanup_previous_worksheet_compile.csv"
                ),
                tags: %i[names cleanup],
                desc: "Joins completed supplied worksheets and deduplicates on "\
                  ":constituentid",
                lookup_on: :constituentid
              }
              Tms::NameTypeCleanup.returned_file_jobs
                .each_with_index do |job, idx|
                  jobname = job.to_s
                    .delete_prefix("name_type_cleanup__")
                    .to_sym
                  register jobname, {
                    path: Tms::NameTypeCleanup.returned_files[idx],
                    desc: "Completed nametype cleanup worksheet",
                    tags: %i[names cleanup],
                    supplied: true
                  }
                end
              register :returned_compile, {
                creator: Kiba::Tms::Jobs::NameTypeCleanup::ReturnedCompile,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "name_type_cleanup_returned_compile.csv"
                ),
                tags: %i[names cleanup],
                desc: "Joins completed cleanup worksheets, adds :cleanupid if "\
                  "it does not exist, and deduplicates on :cleanupid",
                lookup_on: :cleanupid
              }
              register :returned_prep, {
                creator: Kiba::Tms::Jobs::NameTypeCleanup::ReturnedPrep,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "name_type_cleanup_returned_prep.csv"
                ),
                tags: %i[names cleanup],
                desc: "Prepares supplied cleanup spreadsheet for use in "\
                  "overlaying cleaned up data and generating phase 2 name "\
                  "cleanup worksheet"
              }
              register :corrected_name_lookup, {
                creator: Kiba::Tms::Jobs::NameTypeCleanup::CorrectedNameLookup,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "name_type_cleanup_corrected_name_lookup.csv"
                ),
                tags: %i[names cleanup],
                desc: "Creates a table of known correct name/contype "\
                  "combinations, in field :corrfingerprint. Used to avoid "\
                  "marking already-corrected names `for review` in new "\
                  "iterations of name type cleanup worksheet, because value is "\
                  "now coming from a different constituentid",
                lookup_on: :corrfingerprint
              }
              register :corrected_value_lookup, {
                creator: Kiba::Tms::Jobs::NameTypeCleanup::CorrectedValueLookup,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "name_type_cleanup_corrected_value_lookup.csv"
                ),
                tags: %i[names cleanup],
                desc: "Creates a table of known corrected name/contype "\
                  "combinations, in field :corrfingerprint. Used to avoid "\
                  "marking already-corrected names `for review` in new "\
                  "iterations of name type cleanup worksheet, because value is "\
                  "now coming from a different place unaffected by an already-"\
                  "made correction",
                lookup_on: :corrfingerprint
              }
            end
            register :for_con_alt_names, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConAltNames,
              path: File.join(Kiba::Tms.datadir, "working",
                "name_type_cleanup_for_con_alt_names.csv"),
              tags: %i[names cleanup],
              lookup_on: :altnameid
            }
            register :for_constituents, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConstituents,
              path: File.join(Kiba::Tms.datadir, "working",
                "name_type_cleanup_for_constituents.csv"),
              tags: %i[names cleanup],
              lookup_on: :constituentid
            }
            register :for_con_org_with_name_parts, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConOrgWithNameParts,
              path: File.join(Kiba::Tms.datadir, "working",
                "name_type_cleanup_for_con_org_with_name_parts.csv"),
              tags: %i[names cleanup],
              lookup_on: :constituentid
            }
            register :for_con_person_with_inst, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::ForConPersonWithInst,
              path: File.join(Kiba::Tms.datadir, "working",
                "name_type_cleanup_for_con_person_with_inst.csv"),
              tags: %i[names cleanup],
              lookup_on: :constituentid
            }
            register :for_uncontrolled_name_tables, {
              creator: Kiba::Tms::Jobs::NameTypeCleanup::ForUncontrolledNameTables,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "name_type_cleanup_for_uncontrolled_tables.csv"
              ),
              tags: %i[names cleanup],
              lookup_on: :constituentid
            }
          end
        end
      end
    end
  end
end
