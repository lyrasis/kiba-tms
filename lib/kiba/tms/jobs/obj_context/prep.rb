# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjContext
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_context,
                destination: :prep__obj_context,
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :objectid,
                value: '-1'

              if Tms.data_cleaner
                transform Tms.data_cleaner
              end
            end
          end
        end
      end
    end
  end
end
