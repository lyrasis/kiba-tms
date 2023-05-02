# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module ClientDecisionWorksheet
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :packages__flag_migrating,
                destination: :packages__client_decision_worksheet
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[packagetype tablename folderid folderdesc]
            end
          end
        end
      end
    end
  end
end
