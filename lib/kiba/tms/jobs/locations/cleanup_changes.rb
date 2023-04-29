# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module CleanupChanges
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__returned_compile,
                destination: :locs__cleanup_changes
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              # removes client-added, new location rows
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :fulllocid
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[correct_location_name correct_authority
                  correct_address]
            end
          end
        end
      end
    end
  end
end
