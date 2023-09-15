# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module FromOneToOne
          module_function

          def job
            return unless Tms::OneToOneAcq.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :one_to_one_acq__prep,
                destination: :acquisitions__from_one_to_one
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::ConstantValue,
                target: :objaccessiontreatment,
                value: "onetoone"
            end
          end
        end
      end
    end
  end
end
