# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LoanObjXrefs
        module Prep
          extend self

          def job
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
            base = []
            base << :prep__loan_obj_statuses if Tms::LoanObjStatuses.used
            base << :prep__obj_ins_indem_resp if Tms::ObjInsIndemResp.used
            base
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields

              emptyfields = Tms::LoanObjXrefs.empty_fields
              unless emptyfields.empty?
                emptyfields.each do |field|
                  transform Warn::UnlessFieldValueMatches, field: field, match: '^0|$', matchmode: :regexp
                end
              end

              omitted = Tms::LoanObjXrefs.omitted_fields
              unless omitted.empty?
                transform Delete::Fields, fields: omitted
              end

              if Tms::ObjInsIndemResp.used
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
                find: '%CR%',
                replace: "\n"

              if Tms::LoanObjStatuses.used
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
            end
          end
        end
      end
    end
  end
end
