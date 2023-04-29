# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ShippingMethods
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__shipping_methods,
                destination: :prep__shipping_methods
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes,
                field: :shippingmethod
            end
          end
        end
      end
    end
  end
end
