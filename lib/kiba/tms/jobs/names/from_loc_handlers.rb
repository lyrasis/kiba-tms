# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module FromLocHandlers
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__loc_handlers,
                destination: :names__from_loc_handlers
              },
              transformer: xforms,
              helper: Kiba::Tms::Names.compilation.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: :handler
              transform Deduplicate::Table, field: :handler
              transform Rename::Field, from: :handler,
                to: Tms::Constituents.preferred_name_field
              transform Merge::ConstantValue, target: :constituenttype,
                value: "Person"
              transform Merge::ConstantValue, target: :termsource,
                value: "TMS LocHandlers"
              transform Cspace::NormalizeForID,
                source: Tms::Constituents.preferred_name_field, target: :norm
            end
          end
        end
      end
    end
  end
end
