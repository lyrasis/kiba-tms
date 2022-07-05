# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module ForReferenceMasterTodo
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :alt_nums__for_reference_master,
                destination: :alt_nums__for_reference_master_todo
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[beginisodate endisodate],
                target: :combined,
                sep: '',
                delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
            end
          end
        end
      end
    end
  end
end
