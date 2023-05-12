# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module NonNameNotes
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :name_compile__non_name_notes
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  contype = row[:contype]
                  reltype = row[:relation_type]
                  contype &&
                    reltype &&
                    contype.start_with?("Note") &&
                    reltype == "_main term"
                end
              transform Delete::FieldsExcept,
                fields: %i[name prefnormorig contype]
            end
          end
        end
      end
    end
  end
end
