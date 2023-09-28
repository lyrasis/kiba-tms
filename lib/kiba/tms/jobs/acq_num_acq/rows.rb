# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AcqNumAcq
        module Rows
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :acq_num_acq__combined,
                destination: :acq_num_acq__rows
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[objectnumber objectid]
              transform Deduplicate::Table,
                field: :combined,
                delete_field: false
              transform Tms::Transforms::AddIncrementingValue,
                prefix: "acqnum"
              transform Rename::Field,
                from: :acquisitionnumber,
                to: :acquisitionreferencenumber
            end
          end
        end
      end
    end
  end
end
