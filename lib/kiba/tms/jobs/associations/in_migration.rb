# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Associations
        module InMigration
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__associations,
                destination: :associations__in_migration
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :drop,
                value: "n"
              transform Delete::Fields,
                fields: %i[drop dropreason]
            end
          end
        end
      end
    end
  end
end
