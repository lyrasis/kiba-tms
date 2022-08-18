# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module MainDuplicates
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[
                           name_compile__typed_main_duplicates
                           name_compile__untyped_main_duplicates
                          ],
                destination: :name_compile__main_duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
            end
          end
        end
      end
    end
  end
end
