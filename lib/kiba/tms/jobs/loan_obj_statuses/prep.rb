# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LoanObjStatuses
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loan_obj_statuses,
                destination: :prep__loan_obj_statuses
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :loanobjectstatus
              deletes = Tms::LoanObjStatuses.delete_fields
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
