# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationControl
        module Ingest
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :valuation_control__all,
                destination: :valuation_control__ingest
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::FieldsExcept,
                fields: config.cs_fields[Tms.cspace_profile]
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
