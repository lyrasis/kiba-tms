# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module FilePathLookup
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__aws_ls,
                destination: :media_files__file_path_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform do |row|
                row[:norm] = row[:filepath].downcase

                prefix = "#{config.s3_url_base}/"
                row[:filepath] = "#{prefix}#{row[:filepath]}"
                row
              end
            end
          end
        end
      end
    end
  end
end
