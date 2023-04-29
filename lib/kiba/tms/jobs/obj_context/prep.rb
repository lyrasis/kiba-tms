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
                destination: :prep__obj_context
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
                value: "-1"

              transform Tms.data_cleaner if Tms.data_cleaner

              unless config.field_cleaners.empty?
                config.field_cleaners.each { |cleaner| transform cleaner }
              end
            end
          end
        end
      end
    end
  end
end
