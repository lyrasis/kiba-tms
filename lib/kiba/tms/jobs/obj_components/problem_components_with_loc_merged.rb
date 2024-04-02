# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module ProblemComponentsWithLocMerged
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_components__problem_components,
                destination:
                  :obj_components__problem_components_with_loc_merged,
                lookup: %i[
                  locs__compiled_clean
                  tms__obj_locations
                ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: tms__obj_locations,
                keycolumn: :currentobjlocid,
                fieldmap: {
                  currentlocationid: :locationid
                }
              transform Delete::Fields,
                fields: :currentobjlocid
              transform Tms::Transforms::ObjLocations::ConvertPlainLocidToFull,
                fields: %i[homelocationid currentlocationid]

              %i[homelocationid currentlocationid].each do |id|
                target = id.to_s.delete_suffix("id").to_sym
                transform Merge::MultiRowLookup,
                  lookup: locs__compiled_clean,
                  keycolumn: id,
                  fieldmap: {
                    target => :location_name
                  }
                transform Delete::Fields, fields: id
              end
            end
          end
        end
      end
    end
  end
end
