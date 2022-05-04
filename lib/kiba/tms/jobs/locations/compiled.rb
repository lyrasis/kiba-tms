# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module Compiled
          module_function

          def job
            src = Tms.locations.hierarchy ? :locs__compiled_hier_0 : :locs__compiled_0
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: src,
                destination: :locs__compiled,
                lookup: :obj_locations__fulllocid_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Count::MatchingRowsInLookup,
                lookup: obj_locations__fulllocid_lookup,
                keycolumn: :fulllocid,
                targetfield: :usage_ct
              unless Tms.locations.hierarchy
                transform Delete::Fields, fields: :parent_location
              end

              transform Append::NilFields, fields: %i[current_location_note]

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '%QUOT%',
                replace: '"'
            end
          end
        end
      end
    end
  end
end
