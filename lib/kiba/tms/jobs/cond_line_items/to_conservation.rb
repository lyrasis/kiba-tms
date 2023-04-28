# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module CondLineItems
        module ToConservation
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__cond_line_items,
                destination: :cond_line_items__to_conservation
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              logic = ->(row){ row.values.any?(nil) }
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  config.conservation_attribute_types.any?(
                    row[:attributetype]
                  )
                end
            end
          end
        end
      end
    end
  end
end
