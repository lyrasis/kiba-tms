# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AcqNumAcq
        module Combined
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :acq_num_acq__obj_rows,
                destination: :acq_num_acq__combined
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              if Tms::AcqNumAcq.omitting_fields?
                transform Delete::Fields, fields: Tms::AcqNumAcq.omitted_fields
              end
              transform CombineValues::FromFieldsWithDelimiter,
                sources: Tms::AcqNumAcq.content_fields,
                target: :combined,
                delim: " - ",
                prepend_source_field_name: true,
                delete_sources: false
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :combined
            end
          end
        end
      end
    end
  end
end
