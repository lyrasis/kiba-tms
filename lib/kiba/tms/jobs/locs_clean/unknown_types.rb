# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocsClean
        module UnknownTypes
          module_function

          ITERATION = Tms::Locations.cleanup_iteration

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: "locclean#{ITERATION}__prep".to_sym,
                destination: :locclean__unknown_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldMatchRegexp,
                action: :reject,
                field: :storage_location_authority,
                match: '^(Local|Offsite|Organization)$'
            end
          end
        end
      end
    end
  end
end
