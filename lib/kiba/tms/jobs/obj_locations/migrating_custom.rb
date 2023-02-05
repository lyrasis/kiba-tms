# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module MigratingCustom
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__migrating,
                destination: :obj_locations__migrating_custom
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              config.custom_droppers.each{ |dropper| transform dropper }
            end
          end
        end
      end
    end
  end
end
