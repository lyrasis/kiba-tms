# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaMaster
        module PublicBrowserReport
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__media_master,
                destination: :media_master__public_browser_report,
                lookup: :prep__media_renditions
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: prep__media_renditions,
                keycolumn: :primaryrendid,
                fieldmap: {idnumber: :renditionnumber}

              transform Replace::FieldValueWithStaticMapping,
                source: :publicaccess,
                mapping: Tms.boolean_yn_mapping
              transform Replace::FieldValueWithStaticMapping,
                source: :approvedforweb,
                mapping: Tms.boolean_yn_mapping

              transform Delete::FieldsExcept,
                fields: %i[idnumber publicaccess approvedforweb
                  publiccaption remarks restrictions]
            end
          end
        end
      end
    end
  end
end
