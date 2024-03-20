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
              transformer: [
                reduce,
                merge,
                config.post_merge_xforms,
                finalize,
                config.post_prep_xforms
              ].compact
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
            if Tms::TextEntries.for?("Loans")
              base << :text_entries_for__loans
            end
            base
          end

          def reduce
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteEmptyMoney,
                fields: %i[loanfee conservationfee cratefee]
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner
            end
          end

          def merge
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              namefields = config.name_fields - config.omitted_fields

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

              if Tms::IndemnityResponsibilities.used?
                config.indemnity_fields.each do |field|
                  next if config.omitted_fields.any?(field)

                  transform Merge::MultiRowLookup,
                    lookup: prep__indemnity_responsibilities,
                    keycolumn: field,
                    fieldmap: {field => :responsibility}
                  transform Prepend::ToFieldValue,
                    field: field,
                    value: config.indemnity_field_label_map[field]
                end
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.indemnity_fields,
                  target: :indemnityresponsibilities,
                  delim: "%CR%"
              else
                transform Delete::Fields, fields: config.indemnity_fields
              end

              if Tms::InsuranceResponsibilities.used
                config.insurance_fields.each do |field|
                  next if config.omitted_fields.any?(field)

                  transform Merge::MultiRowLookup,
                    lookup: prep__insurance_responsibilities,
                    keycolumn: field,
                    fieldmap: {field => :responsibility}
                  transform Prepend::ToFieldValue,
                    field: field,
                    value: config.insurance_field_label_map[field]
                end
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.insurance_fields,
                  target: :insuranceresponsibilities,
                  delim: "%CR%"
              else
                transform Delete::Fields, fields: config.insurance_fields
              end

              if Tms::Departments.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__departments,
                  keycolumn: :departmentid,
                  fieldmap: {department: :department}
              end
              transform Delete::Fields, fields: :departmentid

              if Tms::TextEntries.for?("Loans")
                if Tms::TextEntriesForLoans.merger_xforms
                  Tms::TextEntriesForLoans.merger_xforms.each do |xform|
                    transform xform
                  end
                else
                  transform Merge::MultiRowLookup,
                    lookup: text_entries_for__loans,
                    keycolumn: :loanid,
                    fieldmap: {text_entry: :text_entry},
                    delim: Tms.delim,
                    sorter: Lookup::RowSorter.new(on: :sort, as: :to_i)
                end
              end

              if Tms::LoanObjXrefs.used? && Tms::LoanObjXrefs.merging_into_loans
                if Tms::LoanObjXrefs.conditions_record == :loan
                  case Tms::LoanObjXrefs.conditions_field
                  when :loanconditions
                    transform Merge::MultiRowLookup,
                      lookup: prep__loan_obj_xrefs,
                      keycolumn: :loanid,
                      fieldmap: {obj_loanconditions: :conditions},
                      delim: "%CR%"
                  end
                end
              end

              namefields.each do |field|
                transform Tms::Transforms::MergeUncontrolledName, field: field
              end
            end
          end

          def finalize
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Replace::FieldValueWithStaticMapping,
                source: :loanin,
                target: :loantype,
                mapping: {"1" => "loan in", "0" => "loan out"}
              transform Clean::DowncaseFieldValues,
                fields: :loanstatus

              transform Delete::EmptyFields

              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.conditions_sources,
                target: :conditions,
                delim: Tms.notedelim
              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.note_sources,
                target: :note,
                delim: Tms.notedelim
            end
          end
        end
      end
    end
  end
end
