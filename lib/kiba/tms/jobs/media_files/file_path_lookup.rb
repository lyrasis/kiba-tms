# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module FilePathLookup
          module_function

          def job
            return unless config.used?
            return unless config.files_uploaded

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
                path = row[:filepath]

                filename = if config.bucket_base_dir
                  path.delete_prefix("#{config.bucket_base_dir}/")
                else
                  path
                end

                row[:norm] = filename.downcase
                row[:filepath] = "#{config.s3_url_base}/#{path}"
                row
              end
            end
          end
        end
      end
    end
  end
end
