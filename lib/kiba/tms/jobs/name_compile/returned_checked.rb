# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module ReturnedChecked
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[
                  name_compile__returned_split_main
                  name_compile__returned_split_note
                  name_compile__returned_split_contact
                  name_compile__returned_split_variant
                ],
                destination: :name_compile__returned_checked
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              # passthrough
            end
          end
        end
      end
    end
  end
end
