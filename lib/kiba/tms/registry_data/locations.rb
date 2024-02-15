# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module Locations
        module_function

        # @todo Create generalizable place/organization extraction
        def register
          Kiba::Tms.registry.namespace("locs") do
            Kiba::Tms::Locations.authorities.each do |type|
              register "#{type}_ingest".to_sym, {
                creator: {
                  callee: Tms::Jobs::Locations::Ingest,
                  args: {type: type}
                },
                path: File.join(
                  Kiba::Tms.datadir,
                  "ingest",
                  "locations-#{type}.csv"
                ),
                desc: "Locations in #{type} vocabulary, prepped for ingest",
                tags: %i[locations ingest]
              }
            end
            register :from_locations, {
              creator: Kiba::Tms::Jobs::Locations::FromLocations,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "locs_from_locations.csv"
              ),
              desc: "Locations extracted from TMS Locations",
              tags: %i[locations]
            }
            register :from_obj_locs, {
              creator: Kiba::Tms::Jobs::Locations::FromObjLocs,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "locs_from_obj_locs.csv"
              ),
              desc: "Locations created by appending :loclevel and/or "\
                ":sublevel to locationid location value",
              tags: %i[locations]
            }
            register :compiled_hier_0, {
              creator: Kiba::Tms::Jobs::Locations::CompiledHier0,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "locs_compiled_hier_0.csv"
              ),
              desc: "Locations from different sources, compiled, hierarchy "\
                "levels added, round 0",
              tags: %i[locations]
            }
            register :compiled_hierarchy, {
              creator: Kiba::Tms::Jobs::Locations::CompiledHierarchy,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "locs_compiled_hierarchy.csv"
              ),
              desc: "Locations from different sources, compiled, hierarchy "\
                "levels added",
              tags: %i[locations]
            }
            register :hierarchy, {
              creator: Kiba::Tms::Jobs::Locations::Hierarchy,
              path: File.join(
                Kiba::Tms.datadir,
                "ingest",
                "locations_hierarchy.csv"
              ),
              desc: "Compiled hierarchy converted into term hierarchy for "\
                "ingest",
              tags: %i[locations ingest]
            }
            register :compiled, {
              creator: Kiba::Tms::Jobs::Locations::Compiled,
              path: File.join(Kiba::Tms.datadir, "working",
                "locs_compiled.csv"),
              desc: "Locations from different sources, compiled, final",
              tags: %i[locations],
              dest_special_opts: {
                initial_headers:
                %i[
                  usage_ct location_name parent_location
                  storage_location_authority address
                  term_source fulllocid
                ]
              },
              lookup_on: :fulllocid
            }
            register :compiled_clean, {
              creator: Kiba::Tms::Jobs::Locations::CompiledClean,
              path: File.join(Kiba::Tms.datadir, "working",
                "locs_compiled_clean.csv"),
              desc: "Locations from different sources, compiled, with cleanup "\
                "applied",
              tags: %i[locations],
              dest_special_opts: {
                initial_headers:
                %i[
                  usage_ct location_name
                  storage_location_authority address
                  term_source fulllocid
                ]
              },
              lookup_on: :fulllocid
            }
            register :worksheet, {
              creator: Kiba::Tms::Jobs::Locations::Worksheet,
              path: File.join(
                Kiba::Tms.datadir,
                "to_client",
                "location_review.csv"
              ),
              desc: "Locations for client review",
              tags: %i[locations],
              dest_special_opts: {
                initial_headers: proc { Tms::Locations.worksheet_columns }
              }
            }
            if Tms::Locations.cleanup_done
              Tms::Locations.provided_worksheet_jobs
                .each_with_index do |job, idx|
                  jobname = job.to_s
                    .delete_prefix("locs__")
                    .to_sym
                  register jobname, {
                    path: Tms::Locations.provided_worksheets[idx],
                    desc: "Locations cleanup/review worksheet provided to "\
                    "client",
                    tags: %i[locations cleanup],
                    supplied: true
                  }
                end
              register :previous_worksheet_compile, {
                creator: Tms::Jobs::Locations::PreviousWorksheetCompile,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "locs_previous_worksheet_compile.csv"
                ),
                tags: %i[locations cleanup],
                desc: "Joins completed supplied worksheets and deduplicates "\
                  "on :fulllocid",
                lookup_on: :fulllocid
              }
              Tms::Locations.returned_file_jobs
                .each_with_index do |job, idx|
                  jobname = job.to_s
                    .delete_prefix("locs__")
                    .to_sym
                  register jobname, {
                    path: Tms::Locations.returned_files[idx],
                    desc: "Completed locations review/cleanup worksheet",
                    tags: %i[locations cleanup],
                    supplied: true
                  }
                end
              register :returned_compile, {
                creator: Tms::Jobs::Locations::ReturnedCompile,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "locs_returned_compile.csv"
                ),
                tags: %i[locations cleanup],
                desc: "Joins completed cleanup worksheets and deduplicates on "\
                  ":fulllocid",
                lookup_on: :fulllocid
              }
              register :cleanup_changes, {
                creator: Tms::Jobs::Locations::CleanupChanges,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "locs_cleanup_changes.csv"
                ),
                tags: %i[locations cleanup],
                desc: "Rows with changes to merge into existing base location "\
                  "data",
                lookup_on: :fulllocid
              }
              register :cleanup_added_locs, {
                creator: Tms::Jobs::Locations::CleanupAddedLocs,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "locs_cleanup_added_locs.csv"
                ),
                tags: %i[locations cleanup],
                desc: "Rows where client added new locations in cleanup data"
              }
            end
          end
        end
      end
    end
  end
end
