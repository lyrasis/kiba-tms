# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module ReturnedToMerge
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
                destination: :name_compile__returned_to_merge
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[fp_editable discarded_edit]
            end
          end
        end
      end
    end
  end
end
