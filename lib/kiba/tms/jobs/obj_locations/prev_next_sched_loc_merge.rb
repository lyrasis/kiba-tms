# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module PrevNextSchedLocMerge
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__location_names_merged,
                destination: :obj_locations__prev_next_sched_loc_merge,
                lookup: :locs__compiled
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: locs__compiled,
                keycolumn: :fulllocid,
                fieldmap: {
                  location: :location_name
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: locs__compiled,
                keycolumn: :prevobjlocid,
                fieldmap: {
                  prev_location: :location_name
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: locs__compiled,
                keycolumn: :nextobjlocid,
                fieldmap: {
                  next_location: :location_name
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: locs__compiled,
                keycolumn: :schedobjlocid,
                fieldmap: {
                  scheduled_location: :location_name
                },
                delim: Tms.delim
              transform Delete::Fields,
                fields: %i[locationid fulllocid prevobjlocid nextobjlocid
                  schedobjlocid]

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[location prev_location next_location
                  scheduled_location],
                target: :locdata,
                sep: "|",
                delete_sources: false
            end
          end
        end
      end
    end
  end
end
