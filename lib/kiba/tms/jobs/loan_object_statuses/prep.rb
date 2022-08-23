# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LoanObjectStatuses
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loan_object_statuses,
                destination: :prep__loan_object_statuses
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :objincomingpurpose
              deletes = Tms::LoanObjectStatuses.delete_fields
              unless deletes.empty?
                transform Delete::Fields, fields: deletes
              end
            end
          end
        end
      end
    end
  end
end
