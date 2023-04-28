# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module Cspace
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__migrating,
                destination: :media_files__cspace
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              csfields = config.media_handling_fields

              transform do |row|
                row.keys.each do |field|
                  row.delete(field) unless csfields.any?(field)
                end
                row
              end
            end
          end
        end
      end
    end
  end
end
