# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LotNumAcq
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.source_job_key,
                destination: :lot_num_acq__prep
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Rename::Fields, fieldmap: {
                acquisitionlot: :acquisitionreferencenumber
              }

              unless config.acq_number_treatment == :drop
                transform Prepend::ToFieldValue,
                  field: :acquisitionnumber,
                  value: config.acq_number_prefix
                targetfield = config.acq_number_treatment
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: [targetfield, :acquisitionnumber],
                  target: targetfield,
                  delim: "\n",
                  delete_sources: true
                transform Clean::RegexpFindReplaceFieldVals,
                  fields: targetfield,
                  find: "%PIPE%",
                  replace: "|"
              end
            end
          end
        end
      end
    end
  end
end
