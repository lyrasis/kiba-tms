# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module NonNameNotesUncontrolled
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__non_name_notes,
                destination: :name_compile__non_name_notes_uncontrolled
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :termsource,
                value: "Uncontrolled"

              transform Delete::Fields,
                fields: %i[termsource constituentid]
            end
          end
        end
      end
    end
  end
end
