# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TermMasterGeo
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__term_master_geo,
                destination: :prep__term_master_geo
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              transform Tms::Transforms::DeleteTmsFields
            end
          end
        end
      end
    end
  end
end
