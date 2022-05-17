# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module AddCounts
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :nameclean__by_constituentid,
                destination: :con_address__add_counts,
                lookup: :con_address__to_merge
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Count::MatchingRowsInLookup,
                lookup: con_address__to_merge,
                keycolumn: :constituentid,
                targetfield: :addresscount
            end
          end
        end
      end
    end
  end
end
