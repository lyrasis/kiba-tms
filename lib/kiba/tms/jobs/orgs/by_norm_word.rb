# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Orgs
        module ByNormWord
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :orgs__by_norm,
                destination: :orgs__by_norm_word
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :finalname
              transform Rename::Field,
                from: :finalname,
                to: :word
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :word,
                find: ' \(duplicate.*\)',
                replace: ""
              transform Explode::RowsFromMultivalField,
                field: :word,
                delim: " "
              transform Deduplicate::Table,
                field: :word
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :word,
                target: :normword
            end
          end
        end
      end
    end
  end
end
