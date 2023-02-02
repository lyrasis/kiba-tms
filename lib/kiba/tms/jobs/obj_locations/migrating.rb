# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Migrating
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_locations,
                destination: :obj_locations__migrating
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :objlocationid,
                value: '-1'
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :locationid,
                value: '-1'
              if config.drop_inactive
                transform FilterRows::FieldEqualTo,
                  action: :reject,
                  field: :inactive,
                  value: '1'
              end
            end
          end
        end
      end
    end
  end
end
