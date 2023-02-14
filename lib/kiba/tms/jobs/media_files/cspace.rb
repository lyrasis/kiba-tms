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
                source: :media_files__shaped,
                destination: :media_files__cspace
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              mod = bind.receiver
              config = mod.send(:config)

              if config.mediafileuri_generator
                transform config.mediafileuri_generator
              end
              transform Delete::Fields,
                fields: %i[fileid path filename fullpath]
            end
          end
        end
      end
    end
  end
end
