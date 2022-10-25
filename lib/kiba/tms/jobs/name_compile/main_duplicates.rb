# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module MainDuplicates
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :name_compile__main_duplicates

              },
              transformer: xforms
            )
          end

          def sources
            %i[name_compile__untyped_main_duplicates
               name_compile__typed_main_duplicates].select do |src|
                Tms.job_output?(src)
              end
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: %i[fromcon combined]
            end
          end
        end
      end
    end
  end
end
