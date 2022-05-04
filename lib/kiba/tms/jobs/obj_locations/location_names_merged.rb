# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module LocationNamesMerged
          module_function

          def job            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_locations,
                destination: :obj_locations__location_names_merged,
                lookup: %i[locs__compiled prep__obj_locations]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: prep__obj_locations,
                keycolumn: :prevobjlocid,
                fieldmap: {
                  prevlocid: :fulllocid,
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: prep__obj_locations,
                keycolumn: :nextobjlocid,
                fieldmap: {
                  nextlocid: :fulllocid,
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: prep__obj_locations,
                keycolumn: :schedobjlocid,
                fieldmap: {
                  schedlocid: :fulllocid,
                },
                delim: Tms.delim
              transform Delete::Fields, fields: %i[prevobjlocid nextobjlocid schedobjlocid]
              
              transform Merge::MultiRowLookup,
                lookup: locs__compiled,
                keycolumn: :fulllocid,
                fieldmap: {
                  location: :location_name,
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: locs__compiled,
                keycolumn: :prevlocid,
                fieldmap: {
                  prev_location: :location_name,
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: locs__compiled,
                keycolumn: :nextlocid,
                fieldmap: {
                  next_location: :location_name,
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: locs__compiled,
                keycolumn: :schedlocid,
                fieldmap: {
                  sched_location: :location_name,
                },
                delim: Tms.delim
              transform Delete::Fields, fields: %i[locationid fulllocid prevlocid nextlocid schedlocid]
            end
          end
        end
      end
    end
  end
end
