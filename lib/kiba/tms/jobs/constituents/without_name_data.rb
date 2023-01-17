# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module WithoutNameData
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__prep_clean,
                destination: :constituents__without_name_data
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :reject, field: :namedata
            end
          end
        end
      end
    end
  end
end
