# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LoanObjXrefs
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loan_obj_xrefs,
                destination: :prep__loan_obj_xrefs,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[prep__loans objects__numbers_cleaned]
            base << :prep__loan_obj_statuses if Tms::LoanObjStatuses.used?
            base << :prep__obj_ins_indem_resp if Tms::ObjInsIndemResp.used?
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              conditions_label = Tms::LoanObjXrefs.conditions_label

              transform Tms::Transforms::DeleteTmsFields

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Merge::MultiRowLookup,
                lookup: prep__loans,
                keycolumn: :loanid,
                fieldmap: {
                  loannumber: :loannumber,
                  loantype: :loantype
                }
              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {objectnumber: :objectnumber}

              if Tms::ObjInsIndemResp.used?
                transform Merge::MultiRowLookup,
                  keycolumn: :insindemrespid,
                  lookup: prep__obj_ins_indem_resp,
                  fieldmap: {
                    insindemresp: :combined
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields, fields: :insindemrespid

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :insindemresp,
                find: "%CR%",
                replace: "\n"

              if Tms::LoanObjStatuses.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__loan_obj_statuses,
                  keycolumn: :loanobjectstatusid,
                  fieldmap: {
                    loanobjectstatus: :loanobjectstatus
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields, fields: :loanobjectstatusid

              transform Tms::Transforms::DeleteEmptyMoney,
                fields: %i[loanfee conservationfee cratefee]

              if conditions_label.is_a?(Symbol)
                transform do |row|
                  cond = row[:conditions]
                  next row if cond.blank?

                  num = row[conditions_label]
                  next row if num.blank?

                  row[:conditions] = "#{num}: #{cond}"
                  row
                end
              elsif conditions_label.is_a?(String)
                transform do |row|
                  cond = row[:conditions]
                  next row if cond.blank?

                  label = conditions_label.sub(
                    "{objectnumber}",
                    row[:objectnumber]
                  ).sub(
                    "{loannumber}",
                    row[:loannumber]
                  )
                  row[:conditions] = "#{label}: #{cond}"
                  row
                end
              else
                warn("Unknown value for Tms::LoanObjXrefs.conditions_label")
              end

              if config.requesteddate_treatment == :loan_status
                transform Rename::Field,
                  from: :requesteddateiso,
                  to: :objreq_loanstatusdate
                transform Merge::ConstantValueConditional,
                  fieldmap: {
                    objreq_loanstatus: "object requested",
                    objreq_loanindividual: "%NULLVALUE%"
                  },
                  condition: ->(row) do
                    !row[:objreq_loanstatusdate].blank?
                  end
                transform do |row|
                  row[:objreq_loanstatusnote] = nil
                  date = row[:objreq_loanstatusdate]
                  next row if date.blank?

                  row[:objreq_loanstatusnote] = row[:objectnumber]
                  row
                end

              end

              if Tms::TextEntries.for?("LoanObjXrefs") &&
                  Tms::TextEntriesForLoanObjXrefs.merger_xforms
                Tms::TextEntriesForLoanObjXrefs.merger_xforms.each do |xform|
                  transform xform
                end
              end

              transform Delete::EmptyFields
            end
          end
        end
      end
    end
  end
end
