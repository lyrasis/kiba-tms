# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjIncPurposes
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_inc_purposes,
                destination: :prep__obj_inc_purposes
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes,
                field: :objincomingpurpose
            end
          end
        end
      end
    end
  end
end
