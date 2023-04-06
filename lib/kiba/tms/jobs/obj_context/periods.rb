# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjContext
        module Periods
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_context,
                destination: :obj_context__periods
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              keep = %i[objectid] + config.date_or_chronology_fields
              transform Delete::FieldsExcept, fields: keep
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: config.date_or_chronology_fields
            end
          end
        end
      end
    end
  end
end
