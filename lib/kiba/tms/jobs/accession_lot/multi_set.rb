# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AccessionLot
        module MultiSet
          module_function

          def job
            return unless Tms::AccessionLot.used
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :accession_lot__set_count,
                destination: :accession_lot__multi_set
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :reject, field: :registrationsets, value: '1'
            end
          end
        end
      end
    end
  end
end
