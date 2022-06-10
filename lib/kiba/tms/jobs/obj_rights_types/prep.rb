# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjRightsTypes
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_rights_types,
                destination: :prep__obj_rights_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :objrightstype
            end
          end
        end
      end
    end
  end
end
