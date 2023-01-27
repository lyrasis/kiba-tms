# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module DuplicatesNotMigrated
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :persons__flagged,
                destination: :persons__duplicates_not_migrated
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :duplicates,
                value: 'y'
              transform Delete::Fields,
                fields: %i[duplicates]
            end
          end
        end
      end
    end
  end
end
