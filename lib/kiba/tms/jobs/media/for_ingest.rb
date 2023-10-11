# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Media
        module ForIngest
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__migrating,
                destination: :media__for_ingest
              },
              transformer: get_xforms
            )
          end

          def get_xforms
            return [xforms] unless config.sampleable?

            [config.sample_xforms, xforms]
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform do |row|
                row.keys.each do |field|
                  row.delete(field) unless config.cs_fields.include?(field)
                end
                row
              end

              transform Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
