# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module ConstituentDuplicateReport
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__duplicates_flagged,
                destination: :name_compile__constituent_duplicate_report
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :constituent_duplicate
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID, source: :name, target: :norm
              transform Tms::Transforms::Constituents::NormalizeContype
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype_norm norm],
                target: :normalized,
                sep: ' ',
                delete_sources: true
            end
          end
        end
      end
    end
  end
end
