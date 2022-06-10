# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module WithType
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__with_name_data,
                destination: :constituents__with_type
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :constituenttype
            end
          end
        end
      end
    end
  end
end
