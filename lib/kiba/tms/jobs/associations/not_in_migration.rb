# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Associations
        module NotInMigration
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__associations,
                destination: :associations__not_in_migration
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :drop,
                value: "y"
              transform Delete::Fields,
                fields: %i[associationid drop id1 id2]
            end
          end
        end
      end
    end
  end
end
