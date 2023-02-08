# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loans
        module Prep
          module_function

          def desc
            "- Deletes TMS fields\n"\
              "- Delete 0 values from money fields\n"\
              "- Delete config empty and deleted fields\n"\
              "- Merge in loan purposes\n"\
              "- Merge in loan statuses\n"\
              "- Merge in indemnity responsibilities\n"\
              "- Merge in insurance responsibilities\n"\
              "- Merge in departments\n"\
              "- Merge in TextEntries data\n"\
              "- Add :loantype with `loan in` or `loan out` value\n"\
              "- If configured to do so:\n"\
              "-- Merge LoanObjXref conditions field data\n"\
              "- For each name field (:approvedby, :contact, "\
              ":reqquestedby):\n"\
              "-- Normalize name value\n"\
              "-- Merge in authorized person/org name value"
          end

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
            base = [:names__by_norm]
            base << :prep__departments if Tms::Departments.used?
            base << :prep__loan_purposes if Tms::LoanPurposes.used?
            base << :prep__loan_statuses if Tms::LoanStatuses.used?
            if Tms::IndemnityResponsibilities.used?
              base << :prep__indemnity_responsibilities
            end
            if Tms::InsuranceResponsibilities.used?
              base << :prep__insurance_responsibilities
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
              namefields = config.name_fields - config.omitted_fields

              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteEmptyMoney,
                fields: %i[loanfee conservationfee cratefee]
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

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

              indfields = %i[indemnityfromlender indemnityfrompreviousvenue
                             indemnityatvenue indemnityreturn]
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

              insfields = %i[insurancefromlender insurancefrompreviousvenue
                             insuranceatvenue insurancereturn]
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

              if Tms::Departments.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__departments,
                  keycolumn: :departmentid,
                  fieldmap: {department: :department}
              end
              transform Delete::Fields, fields: :departmentid

              if Tms::TextEntries.for?('Loans')
                transform Merge::MultiRowLookup,
                  lookup: text_entries_for__loans,
                  keycolumn: :loanid,
                  fieldmap: {text_entry: :text_entry},
                  delim: Tms.delim,
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i)
              end

              transform Replace::FieldValueWithStaticMapping,
                source: :loanin,
                target: :loantype,
                mapping: {'1'=>'loan in', '0'=>'loan out'}

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

              namefields.each do |field|
                transform Tms::Transforms::MergeUncontrolledName, field: field
              end
            end
          end
        end
      end
    end
  end
end
