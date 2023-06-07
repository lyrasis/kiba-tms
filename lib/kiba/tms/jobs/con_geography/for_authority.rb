# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConGeography
        module ForAuthority
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_geography,
                destination: :con_geography__for_authority
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

              transform config.auth_cleaner if config.auth_cleaner

              transform Delete::Fields,
                fields: config.non_content_fields
              transform Merge::ConstantValue,
                target: :sourcetable,
                value: 'ConGeography'
            end
          end
        end
      end
    end
  end
end
