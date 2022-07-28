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
                lookup: %i[prep__obj_ins_indem_resp]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              
              unless Tms::LoanObjXrefs.delete_fields.empty?
                transform Delete::Fields, fields: Tms::LoanObjXrefs.delete_fields
              end

              transform Merge::MultiRowLookup,
                keycolumn: :insindemrespid,
                lookup: prep__obj_ins_indem_resp,
                fieldmap: {
                  insindemresp: :combined
                },
                delim: Tms.delim
              transform Delete::Fields, fields: :insindemrespid
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :insindemresp,
                find: '%CR%',
                replace: "\n"
              transform Tms::Transforms::DeleteEmptyMoney,
                fields: %i[loanfee conservationfee cratefee]
            end
          end
        end
      end
    end
  end
end
