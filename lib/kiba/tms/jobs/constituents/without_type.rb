# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module WithoutType
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__with_name_data,
                destination: :constituents__without_type
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :reject, field: :constituenttype
              transform Tms::Transforms::Constituents::DeriveType
            end
          end
        end
      end
    end
  end
end
