# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConXrefDetails
        module ForLoans
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_xref_details,
                destination: :con_xref_details__for_loans
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep,
                field: :tablename, value: "Loans"
              transform Delete::Fields, fields: :tablename
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[recordid role person org],
                target: :combined,
                delim: " ",
                delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true
              if Tms::ConXrefDetails.for_loans.con_note_builder
                transform { |row|
                  Tms::ConXrefDetails.for_loans.con_note_builder.process(row)
                }
              end
            end
          end
        end
      end
    end
  end
end
