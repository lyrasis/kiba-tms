# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__numbers_cleaned,
                destination: :prep__objects
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
