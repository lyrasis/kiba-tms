# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConGeography
        module ForNonAuthority
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_geography,
                destination: :con_geography__for_non_authority
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::WithLambda,
                action: :reject,
                lambda: config.controlled_type_condition

              if config.non_auth_cleaner
                transform config.non_auth_cleaner
              end
            end
          end
        end
      end
    end
  end
end
