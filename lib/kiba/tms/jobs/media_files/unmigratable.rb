# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module Unmigratable
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__target_report,
                destination: :media_files__unmigratable
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  val = row[:targettable]
                  return false if val.blank?

                  val.split(Tms.delim)
                    .reject { |v| config.unmigratable_targets.any?(v) }
                    .empty?
                end
              transform Merge::ConstantValue,
                target: :unmigratable_reason,
                value: "target table cannot be linked to media in CS"
            end
          end
        end
      end
    end
  end
end
