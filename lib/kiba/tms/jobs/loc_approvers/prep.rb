# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocApprovers
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loc_approvers,
                destination: :prep__loc_approvers
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :approver
            end
          end
        end
      end
    end
  end
end
