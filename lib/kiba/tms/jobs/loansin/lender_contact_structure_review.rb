# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansin
        module LenderContactStructureReview
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loansin__prep,
                destination: :loansin__lender_contact_structure_review
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[loaninnumber lenderpersonlocal
                  lenderorganizationlocal lenderscontact]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[lenderpersonlocal lenderorganizationlocal],
                target: :combined,
                delim: Tms.delim,
                delete_sources: false
              %i[combined lenderscontact].each do |field|
                transform do |row|
                  target = "#{field}_ct".to_sym
                  row[target] = 0
                  val = row[field]
                  next row if val.blank?

                  row[target] = val.split(Tms.delim)
                    .length
                  row
                end
              end
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :lenderscontact_ct,
                value: 0
              transform FilterRows::WithLambda,
                action: :reject,
                lambda: ->(row) {
                  row[:combined_ct] == 1 && row[:lenderscontact_ct] == 1
                }
              transform Delete::Fields, fields: :combined
              transform Rename::Field,
                from: :combined_ct,
                to: :lender_ct
            end
          end
        end
      end
    end
  end
end
