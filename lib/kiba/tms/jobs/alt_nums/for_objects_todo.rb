# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module ForObjectsTodo
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :alt_nums__for_objects,
                destination: :alt_nums__for_objects_todo
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :endisodate
            end
          end
        end
      end
    end
  end
end
