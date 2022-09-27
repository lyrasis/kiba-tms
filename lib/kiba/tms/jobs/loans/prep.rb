# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loans
        module Prep
          module_function

          def job
            return unless config.used?

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
            base = []
            base << :prep__departments if Tms::Departments.used?
            base << :prep__loan_purposes if Tms::LoanPurposes.used?
            base << :prep__loan_statuses if Tms::LoanStatuses.used?
            if Tms::IndemnityResponsibilities.used?
              base << :prep__indemnity_responsibilities
            end
            if Tms::InsuranceResponsibilities.used?
              base << :prep__insurance_responsibilities
            end
            if Tms::Loans.con_link_field == :primaryconxrefid &&
                Tms::ConRefs.for?('Loans')
              base << :con_refs_for__loans
            else
              warn('Implement other Tms::Loans.con_link_field')
            end
            if Tms::LoanObjXrefs.used? && Tms::LoanObjXrefs.merging_into_loans
              base << :prep__loan_obj_xrefs
            end
            if Tms::TextEntries.for?('Loans')
              base << :text_entries_for__loans
            end
            base
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteEmptyMoney,
                fields: %i[loanfee conservationfee cratefee]

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if Tms::LoanPurposes.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__loan_purposes,
                  keycolumn: :loanpurposeid,
                  fieldmap: {loanpurpose: :loanpurpose}
              end
              transform Delete::Fields, fields: :loanpurposeid

              if Tms::LoanStatuses.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__loan_statuses,
                  keycolumn: :loanstatusid,
                  fieldmap: {loanstatus: :loanstatus}
              end
              transform Delete::Fields, fields: :loanstatusid

              indfields = %i[indemnityfromlender indemnityfrompreviousvenue indemnityatvenue indemnityreturn]
              if Tms::IndemnityResponsibilities.used?
                indfields.each do |field|
                  next if config.omitted_fields.any?(field)

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
                  next if config.omitted_fields.any?(field)

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

              if Tms::Departments.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__departments,
                  keycolumn: :departmentid,
                  fieldmap: {department: :department}
              end
              transform Delete::Fields, fields: :departmentid

              if Tms::Loans.con_link_field == :primaryconxrefid && Tms::ConRefs.for?('Loans')
                transform Merge::MultiRowLookup,
                  lookup: con_refs_for__loans,
                  keycolumn: :loanid,
                  fieldmap: {person: :person, personrole: :role},
                  delim: Tms.delim,
                  null_placeholder: Tms.nullvalue,
                  conditions: ->(_orig, mrows){ mrows.reject{ |row| row[:person].blank? } },
                  sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i)
                transform Merge::MultiRowLookup,
                  lookup: con_refs_for__loans,
                  keycolumn: :loanid,
                  fieldmap: {org: :org, orgrole: :role},
                  delim: Tms.delim,
                  null_placeholder: Tms.nullvalue,
                  conditions: ->(_orig, mrows){ mrows.reject{ |row| row[:org].blank? } },
                  sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i)
              end
              transform Delete::Fields, fields: :primaryconxrefid

              if Tms::LoanObjXrefs.used? && Tms::LoanObjXrefs.merging_into_loans
                if Tms::LoanObjXrefs.conditions_record == :loan
                  case Tms::LoanObjXrefs.conditions_field
                  when :loanconditions
                    transform Merge::MultiRowLookup,
                      lookup: prep__loan_obj_xrefs,
                      keycolumn: :loanid,
                      fieldmap: {obj_loanconditions: :conditions},
                      delim: '%CR%'
                  end
                end
              end

              if Tms::TextEntries.for?('Loans')
                transform Merge::MultiRowLookup,
                  lookup: text_entries_for__loans,
                  keycolumn: :loanid,
                  fieldmap: {text_entry: :text_entry},
                  delim: Tms.delim,
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i)
              end
            end
          end
        end
      end
    end
  end
end
