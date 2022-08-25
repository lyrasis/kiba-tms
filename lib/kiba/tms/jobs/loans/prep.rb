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
            base << :prep__loan_statuses if Tms::LoanStatuses.used
            base << :prep__indemnity_responsibilities if Tms::IndemnityResponsibilities.used
            base << :prep__insurance_responsibilities if Tms::InsuranceResponsibilities.used
            if Tms::Loans.con_link_field == :primaryconxrefid && Tms::ConXrefDetails.for?('Loans')
              base << :con_xref_details__for_loans
            else
              warn('Implement other Tms::Loans.con_link_field')
            end
            base << :prep__loan_obj_xrefs if Tms::LoanObjXrefs.used && Tms::LoanObjXrefs.merging_into_loans
            base
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteEmptyMoney,
                fields: %i[loanfee conservationfee cratefee]

              unless Tms::Loans.empty_fields.empty?
                Tms::Loans.empty_fields.each do |field|
                  transform Warn::UnlessFieldValueMatches, field: field, match: '^0|$', matchmode: :regexp
                end
              end
              
              unless Tms::Loans.omitted_fields.empty?
                transform Delete::Fields, fields: Tms::Loans.omitted_fields
              end

              if Tms::LoanPurposes.used
                transform Merge::MultiRowLookup,
                  lookup: prep__loan_purposes,
                  keycolumn: :loanpurposeid,
                  fieldmap: {loanpurpose: :loanpurpose}

                Tms::LoanPurposes.unused_values.each do |val|
                  transform Warn::IfFieldValueMatches, field: :loanpurpose, match: val
                end
              end
              transform Delete::Fields, fields: :loanpurposeid

              if Tms::LoanStatuses.used
                transform Merge::MultiRowLookup,
                  lookup: prep__loan_statuses,
                  keycolumn: :loanstatusid,
                  fieldmap: {loanstatus: :loanstatus}
              end
              transform Delete::Fields, fields: :loanstatusid

              indfields = %i[indemnityfromlender indemnityfrompreviousvenue indemnityatvenue indemnityreturn]
              if Tms::IndemnityResponsibilities.used
                indfields.each do |field|
                  next if Tms::Loans.omitted_fields.any?(field)

                  transform Merge::MultiRowLookup,
                    lookup: prep__indemnity_responsibilities,
                    keycolumn: field,
                    fieldmap: {field => :responsibility}
                end
              else
                transform Delete::Fields, fields: indfields
              end

              insfields = %i[insurancefromlender insurancefrompreviousvenue insuranceatvenue insurancereturn]
              if Tms::InsuranceResponsibilities.used
                insfields.each do |field|
                  next if Tms::Loans.omitted_fields.any?(field)

                  transform Merge::MultiRowLookup,
                    lookup: prep__insurance_responsibilities,
                    keycolumn: field,
                    fieldmap: {field => :responsibility}
                end
              else
                transform Delete::Fields, fields: insfields
              end

              transform Replace::FieldValueWithStaticMapping,
                source: :loanin,
                target: :loantype,
                mapping: {'1'=>'loan in', '0'=>'loan out'}

              transform Merge::MultiRowLookup,
                lookup: prep__departments,
                keycolumn: :departmentid,
                fieldmap: {department: :department}
              transform Delete::Fields, fields: :departmentid

              if Tms::Loans.con_link_field == :primaryconxrefid && Tms::ConXrefDetails.for?('Loans')
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

              if Tms::LoanObjXrefs.conditions.record == :loan
                case Tms::LoanObjXrefs.conditions.field
                when :loanconditions
                  transform Merge::MultiRowLookup,
                    lookup: prep__loan_obj_xrefs,
                    keycolumn: :loanid,
                    fieldmap: {obj_loanconditions: :conditions},
                    delim: '%CR%'
                end
              end
            end
          end
        end
      end
    end
  end
end
