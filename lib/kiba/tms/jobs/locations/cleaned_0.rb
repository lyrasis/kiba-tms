# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module Cleaned0
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__cleaned0,
                destination: :locs__cleaned0,
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
