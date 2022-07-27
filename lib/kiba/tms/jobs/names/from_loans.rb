# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module FromLoans
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__loans,
                destination: :names__from_loans
              },
              transformer: xforms,
              helper: Kiba::Tms.name_compilation.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[approvedby contact requestedby]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[approvedby contact requestedby], target: :combined,
                sep: '|||', delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Delete::FieldsExcept, fields: :combined
              transform Explode::RowsFromMultivalField, field: :combined, delim: '|||'
              transform Deduplicate::Table, field: :combined
              transform Cspace::NormalizeForID, source: :combined, target: :norm
              transform Rename::Field, from: :combined, to: Tms::Constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Loans'
            end
          end
        end
      end
    end
  end
end
