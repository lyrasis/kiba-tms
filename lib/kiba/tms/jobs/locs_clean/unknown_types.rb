# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocsClean
        module UnknownTypes
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locclean0__prep,
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
