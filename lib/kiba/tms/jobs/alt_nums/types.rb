# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module Types
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :alt_nums__description_occs,
                destination: :alt_nums__types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, keepfields: %i[description tablename desc_occs]
              transform CombineValues::FromFieldsWithDelimiter, sources: %i[tablename description], target: :combined,
                sep: ': ', delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true
            end
          end
        end
      end
    end
  end
end
