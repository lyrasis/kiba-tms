# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module Unique
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__compile,
                destination: :places__unique,
                lookup: :places__compile
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :orig_combined,
                delete_field: false
              transform Count::MatchingRowsInLookup,
                lookup: places__compile,
                keycolumn: :orig_combined,
                targetfield: :occurrences
            end
          end
        end
      end
    end
  end
end
