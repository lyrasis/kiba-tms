# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Conditions
        module Objects
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :conditions_for__objects,
                destination: :conditions__objects
              },
              transformer: xforms,
              helper: Tms::Conditions.multisource_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Rename::Field, from: :objectnumber, to: :recordnumber
            end
          end
        end
      end
    end
  end
end
