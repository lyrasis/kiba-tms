# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loans
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loans,
                destination: :prep__loans,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
                      prep__departments
                     ]
            base << :prep__loan_purposes if Tms::LoanPurposes.used
            if Tms::Loans.con_link_field == :primaryconxrefid && Tms::ConXrefDetails.for_loans.any
              base << :con_xref_details__for_loans
            else
              warn('Implement other Tms::Loans.con_link_field')
            end
            base
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteEmptyMoney,
                fields: %i[loanfee conservationfee cratefee]
              
              unless Tms::Loans.omitted_fields.empty?
                transform Delete::Fields, fields: Tms::Loans.omitted_fields
              end

              if Tms::LoanPurposes.used
                transform Merge::MultiRowLookup,
                  lookup: prep__loan_purposes,
                  keycolumn: :loanpurposeid,
                  fieldmap: {loanpurpose: :loanpurpose}
              end
              transform Delete::Fields, fields: :loanpurposeid

              transform Replace::FieldValueWithStaticMapping,
                source: :loanin,
                target: :loantype,
                mapping: {'1'=>'loan in', '0'=>'loan out'}

              transform Merge::MultiRowLookup,
                lookup: prep__departments,
                keycolumn: :departmentid,
                fieldmap: {department: :department}
              transform Delete::Fields, fields: :departmentid

              if Tms::Loans.con_link_field == :primaryconxrefid && Tms::ConXrefDetails.for_loans.any
                transform Merge::MultiRowLookup,
                  lookup: con_xref_details__for_loans,
                  keycolumn: :loanid,
                  fieldmap: {person: :person, personrole: :role},
                  delim: Tms.delim,
                  null_placeholder: Tms.nullvalue,
                  conditions: ->(_orig, mrows){ mrows.reject{ |row| row[:person].blank? } },
                  sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i)
                transform Merge::MultiRowLookup,
                  lookup: con_xref_details__for_loans,
                  keycolumn: :loanid,
                  fieldmap: {org: :org, orgrole: :role},
                  delim: Tms.delim,
                  null_placeholder: Tms.nullvalue,
                  conditions: ->(_orig, mrows){ mrows.reject{ |row| row[:org].blank? } },
                  sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i)
              end
              transform Delete::Fields, fields: :primaryconxrefid
            end
          end
        end
      end
    end
  end
end
