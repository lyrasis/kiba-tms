# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module NotMigrating
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__shaped,
                destination: :media_files__not_migrating
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              unless config.migrate_fileless
                transform FilterRows::FieldPopulated,
                  action: :reject,
                  field: :mediafileuri
              end
            end
          end
        end
      end
    end
  end
end
