# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module FromBaseData
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :name_type_cleanup__from_base_data
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :relation_type,
                value: "_main term"
              transform Delete::Fields,
                fields: %i[
                           sort relation_type variant_term variant_qualifier
                           related_term related_role note_text
                          ]
            end
          end
        end
      end
    end
  end
end
