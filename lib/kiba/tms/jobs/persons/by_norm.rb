# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module ByNorm
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :persons__by_norm
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
                    contype.start_with?('Person') &&
                    reltype == '_main term'
                end
              transform Delete::FieldsExcept, fields: :name
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :name,
                target: :norm
            end
          end
        end
      end
    end
  end
end
