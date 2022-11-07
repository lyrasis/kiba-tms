# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansin
        module Creditlines
          module_function

          def job
            return unless config.used?
            return unless Tms::ObjAccesion.loaned_object_treatment ==
              :creditline_to_loanin

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loans__in,
                destination: :loansin__creditlines,
                lookup: :objects__loan_in_creditlines
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: :loanid
            end
          end
        end
      end
    end
  end
end
