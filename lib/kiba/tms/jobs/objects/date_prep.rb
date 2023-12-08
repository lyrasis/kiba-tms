# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module DatePrep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__objects,
                destination: :objects__date_prep
              },
              transformer: [
                narrow,
                config.date_prep_initial_cleaners,
                xforms,
                config.date_prep_final_cleaners
              ].compact
            )
          end

          def narrow
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              keep = %i[objectid objectnumber] + config.date_fields
              transform Delete::FieldsExcept, fields: keep
              transform Delete::FieldValueMatchingRegexp,
                fields: config.date_fields,
                match: "^0$"
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: config.date_fields
            end
          end

          def xforms
            Kiba.job_segment do
              # passthrough
            end
          end
        end
      end
    end
  end
end
