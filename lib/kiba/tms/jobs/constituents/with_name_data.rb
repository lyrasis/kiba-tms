# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module WithNameData
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__constituents,
                destination: :constituents__with_name_data
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :namedata
              transform Delete::Fields, fields: :namedata
            end
          end
        end
      end
    end
  end
end
