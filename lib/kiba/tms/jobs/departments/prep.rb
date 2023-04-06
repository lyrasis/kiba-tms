# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Departments
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__departments,
                destination: :prep__departments
              },
              transformer: [
                xforms,
                config.multitable_xforms(binding)
              ]
            )
          end

          def xforms
            Kiba.job_segment do
              transform Rename::Field,
                from: :maintableid,
                to: :tableid
            end
          end
        end
      end
    end
  end
end
