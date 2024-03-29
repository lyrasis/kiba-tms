# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhVenObjXrefs
        module Report
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__exh_ven_obj_xrefs,
                destination: :exh_ven_obj_xrefs__report
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
