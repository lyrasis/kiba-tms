# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AccessionLot
        module SetCount
          module_function

          def job
            return unless Tms::AccessionLot.used
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__accession_lot,
                destination: :accession_lot__set_count,
                lookup: :tms__registration_sets
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[acquisitionlotid]
              transform Count::MatchingRowsInLookup,
                lookup: tms__registration_sets,
                keycolumn: :acquisitionlotid,
                targetfield: :registrationsets
            end
          end
        end
      end
    end
  end
end
