# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhVenObjXrefs
        module Prep
          module_function

          def prep
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__exh_ven_obj_xrefs,
                destination: :prep__exh_ven_obj_xrefs,
                lookup: %i[prep__obj_ins_indem_resp]
              },
              transformer: prep_xforms
            )
          end

          def lookups
            base = []
            base << :prep__obj_ins_indem_resp if Tms::ObjInsIndemResp.used?
            base
          end

          def prep_xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              if Tms::ExhVenObjXrefs.omitting_fields?
              transform Delete::Fields,
                fields: Tms::ExhVenObjXrefs.omitted_fields
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
            end
          end
        end
      end
    end
  end
end
