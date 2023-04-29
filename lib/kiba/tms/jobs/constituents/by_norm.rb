# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module ByNorm
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__prep_clean,
                destination: :constituents__by_norm
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :norm
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype norm],
                target: :combined,
                sep: " ",
                delete_sources: false
              transform Delete::FieldsExcept,
                fields: config.lookup_job_fields
            end
          end
        end
      end
    end
  end
end
