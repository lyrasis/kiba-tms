# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module Media
        module_function

        # @todo Create generalizable place/organization extraction
        def register
          Kiba::Tms.registry.namespace("media") do
            register :for_ingest, {
              creator: Kiba::Tms::Jobs::Media::ForIngest,
              path: File.join(
                Kiba::Tms.datadir,
                "ingest",
                "media.csv"
              ),
              desc: "Removes non-CS fields",
              tags: %i[media_files media ingest]
            }
          end

          Kiba::Tms.registry.namespace("media_files") do
            register :aws_ls, {
              supplied: true,
              path: File.join(
                Kiba::Tms.datadir, "supplied", "aws_ls.csv"
              )
            }
            register :file_path_lookup, {
              creator: Kiba::Tms::Jobs::MediaFiles::FilePathLookup,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "media_files_path_lookup.csv"
              ),
              desc: "Adds normalized form of file path for lookup of actual "\
                "media file paths in S3",
              tags: %i[media_files media],
              lookup_on: :norm
            }
            register :migratable, {
              creator: Kiba::Tms::Jobs::MediaFiles::Migratable,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "media_files_migratable.csv"
              ),
              desc: "Removes rows for media files included in "\
                ":media_files__unmigratable_report",
              tags: %i[media_files media]
            }
            register :migratable_files, {
              creator: Kiba::Tms::Jobs::MediaFiles::MigratableFiles,
              path: File.join(
                Kiba::Tms.datadir,
                "reports",
                "media_files_migratable.csv"
              ),
              desc: "List of unique media files (deduplicated on :fullpath "\
                "value), with :filesize, :memorysize. Give to client so they "\
                "can location and transfer media files to S3 for ingest.",
              tags: %i[media_files media reports],
              dest_special_opts: {
                initial_headers: %i[fullpath filename filesize memorysize]
              }
            }
            register :shaped, {
              creator: Kiba::Tms::Jobs::MediaFiles::Shaped,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "media_files_shaped.csv"
              ),
              desc: "Media files data reshaped for CS; Creates :mediafileuri",
              tags: %i[media_files media]
            }
            register :migrating, {
              creator: Kiba::Tms::Jobs::MediaFiles::Migrating,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "media_files_migrating.csv"
              ),
              desc: "Removes rows without files, if not migrating fileless "\
                "media; Adds :identificationnumber",
              tags: %i[media_files media],
              lookup_on: :mediafileuri
            }
            register :not_migrating, {
              creator: Kiba::Tms::Jobs::MediaFiles::NotMigrating,
              path: File.join(
                Kiba::Tms.datadir,
                "reports",
                "media_files_not_migrating.csv"
              ),
              desc: "Lists TMS media data rows that cannot be matched to a "\
                "media file in S3",
              tags: %i[media_files media reports]
            }
            register :duplicate_files, {
              creator: Kiba::Tms::Jobs::MediaFiles::DuplicateFiles,
              path: File.join(
                Kiba::Tms.datadir,
                "reports",
                "media_files_duplicate_files.csv"
              ),
              desc: "Records where the same filepath is used in more than one "\
                "MediaFiles record. Typically we create one Media Handling "\
                "procedure in CS from each MediaFiles record. We want to "\
                "only ingest each file once in CS, and there is no way to "\
                "have multiple Media Handling records describing the same file "\
                "in CS. Where there are multiple TMS records for the same file, "\
                "we can't know what descriptive data the client wants to retain "\
                "in the migration for that file. We provide this report for "\
                "initial decision-making on how to handle these.",
              tags: %i[media_files media reports],
              dest_special_opts: {
                initial_headers:
                %i[fullpath rend_renditionnumber file_entered_date filedate
                  rend_renditiondate rend_mediatype rend_quality rend_remarks]
              }
            }
            register :id_lookup, {
              creator: Kiba::Tms::Jobs::MediaFiles::IdLookup,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "media_files_id_lookup.csv"
              ),
              desc: "Get :identificationnumber via :fileid",
              tags: %i[media_files],
              lookup_on: :mediamasterid
            }
            register :file_names, {
              creator: Kiba::Tms::Jobs::MediaFiles::FileNames,
              path: File.join(
                Kiba::Tms.datadir,
                "reports",
                "media_file_names.csv"
              ),
              desc: "List of media file names only",
              tags: %i[media_files reports]
            }
            register :no_filename, {
              creator: Kiba::Tms::Jobs::MediaFiles::NoFilename,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "media_files_no_filename.csv"
              ),
              desc: "MediaXrefs::TargetReport rows where :filename is not "\
                "populated. MediaXrefs::TargetReport is the source only so "\
                "output columns will match unmigratable and unreferenced",
              tags: %i[media_files]
            }
            register :target_report, {
              creator: Kiba::Tms::Jobs::MediaFiles::TargetReport,
              path: File.join(
                Kiba::Tms.datadir,
                "reports",
                "media_file_target_tables.csv"
              ),
              desc: "Merges MediaXrefs target tables into MediaFiles::Prep",
              tags: %i[media_files reports],
              dest_special_opts: {
                initial_headers: %i[targettable fullpath_duplicate
                  filename_duplicate path filename]
              }
            }
            register :unmigratable_report, {
              creator: Kiba::Tms::Jobs::MediaFiles::UnmigratableReport,
              path: File.join(
                Kiba::Tms.datadir,
                "reports",
                "media_files_unmigratable.csv"
              ),
              desc: "MediaXrefs::TargetReport rows where :targettable is empty "\
                "or contains only tables that cannot be related to Media "\
                "Handling procedures",
              tags: %i[media_files reports],
              lookup_on: :fileid
            }
            register :unmigratable, {
              creator: Kiba::Tms::Jobs::MediaFiles::Unmigratable,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "media_files_unmigratable.csv"
              ),
              desc: "MediaXrefs::TargetReport rows where :targettable contains "\
                "only tables that cannot be related to Media Handling procedures",
              tags: %i[media_files]
            }
            register :unreferenced, {
              creator: Kiba::Tms::Jobs::MediaFiles::Unreferenced,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "media_files_unreferenced.csv"
              ),
              desc: "MediaXrefs::TargetReport rows where :targettable is empty",
              tags: %i[media_files]
            }
            register :nhr_report, {
              creator: Kiba::Tms::Jobs::MediaFiles::NhrReport,
              path: File.join(
                Kiba::Tms.datadir,
                "reports",
                "media_files_relationships.csv"
              ),
              desc: "Summary of nonhierarchical relationships between Media and "\
                "other record types",
              tags: %i[media_files]
            }
            register :not_matched_to_record, {
              creator: Kiba::Tms::Jobs::MediaFiles::NotMatchedToRecord,
              path: File.join(
                Kiba::Tms.datadir,
                "reports",
                "media_files_not_matched_to_record.csv"
              ),
              desc: "List of media files uploaded to S3 that cannot be matched "\
                "TMS data on normalized file path",
              tags: %i[media_files reports]
            }
          end

          Tms.registry.namespace("media_master") do
            register :public_browser_report, {
              creator: Kiba::Tms::Jobs::MediaMaster::PublicBrowserReport,
              path: File.join(Kiba::Tms.datadir, "reports",
                "media_public_browser_report.csv"),
              desc: "Support client approval of logic for publishing to "\
                "CollectionSpace public browser",
              tags: %i[media_master reports]
            }
          end

          Kiba::Tms.registry.namespace("media_xrefs") do
            register :nhrs, {
              creator: Kiba::Tms::Jobs::MediaXrefs::Nhrs,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_media.csv"
              ),
              desc: "All Media NHRs",
              tags: %i[media nhr],
              lookup_on: :item2_id
            }
            register :accession_lot, {
              creator: Kiba::Tms::Jobs::MediaXrefs::AccessionLot,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_media_accession_lot.csv"
              ),
              desc: "Media <-> Acquisition NHRs through AccessionLot",
              tags: %i[media acquisitions nhr]
            }
            register :cond_line_items, {
              creator: Kiba::Tms::Jobs::MediaXrefs::CondLineItems,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_media_cond_line_items.csv"
              ),
              desc: "Media <-> ConditionCheck NHRs through CondLineItems",
              tags: %i[media acquisitions nhr]
            }
            register :exhibitions, {
              creator: Kiba::Tms::Jobs::MediaXrefs::Exhibitions,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_media_exhibitions.csv"
              ),
              desc: "Media <-> Exhibition NHRs",
              tags: %i[media exhibitions nhr]
            }
            register :loansin, {
              creator: Kiba::Tms::Jobs::MediaXrefs::Loansin,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_media_loansin.csv"
              ),
              desc: "Media <-> Loans In NHRs",
              tags: %i[media loansin nhr]
            }
            register :loansout, {
              creator: Kiba::Tms::Jobs::MediaXrefs::Loansout,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_media_loansout.csv"
              ),
              desc: "Media <-> Loans Out NHRs",
              tags: %i[media loansout nhr]
            }
            register :obj_insurance, {
              creator: Kiba::Tms::Jobs::MediaXrefs::ObjInsurance,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_media_obj_insurance.csv"
              ),
              desc: "Media <-> Valuation Control NHRs",
              tags: %i[media obj_insurance valuation_control nhr]
            }
            register :obj_rights, {
              creator: Kiba::Tms::Jobs::MediaXrefs::ObjRights,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_media_obj_rights.csv"
              ),
              desc: "Media <-> Object NHRs (through ObjRights)",
              tags: %i[media obj_rights objects nhr]
            }
            register :objects, {
              creator: Kiba::Tms::Jobs::MediaXrefs::Objects,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "nhr_media_object.csv"
              ),
              desc: "Media <-> Object NHRs",
              tags: %i[media objects nhr]
            }
            register :for_target_report, {
              creator: Kiba::Tms::Jobs::MediaXrefs::ForTargetReport,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "media_xrefs_for_target_report.csv"
              ),
              desc: "Lookup table used to merge target tables into media files "\
                "report",
              tags: %i[media_xrefs reports],
              lookup_on: :mediamasterid
            }
          end
        end
      end
    end
  end
end
