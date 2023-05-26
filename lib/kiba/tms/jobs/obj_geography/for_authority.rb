# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module ForAuthority
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_geography,
                destination: :obj_geography__for_authority
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
                lambda: config.controlled_type_condition
            end
          end
        end
      end
    end
  end
end
