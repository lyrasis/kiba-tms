# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConservationTreatments
        module NhrsCondLineItems
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :conservation_treatments__all,
                destination: :conservation_treatments__nhrs_cond_line_items
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :datasource,
                value: "CondLineItems"
              transform Tms::Transforms::ConservationTreatments::CreateCondLineItemNhrs
            end
          end
        end
      end
    end
  end
end
