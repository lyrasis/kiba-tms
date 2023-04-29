# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module NoDescription
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__alt_nums,
                destination: :alt_nums__no_description
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :reject,
                field: :description
            end
          end
        end
      end
    end
  end
end
