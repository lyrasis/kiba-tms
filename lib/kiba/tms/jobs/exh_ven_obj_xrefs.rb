# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhVenObjXrefs
        extend self

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

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields,
              fields: %i[lightexpluxperhour remarks begindispldateiso enddispldateiso catalognumber]

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
