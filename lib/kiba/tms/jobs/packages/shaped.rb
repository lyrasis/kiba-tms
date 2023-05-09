# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module Shaped
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :packages__migrating,
                destination: :packages__shaped
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
            end
          end
        end
      end
    end
  end
end
