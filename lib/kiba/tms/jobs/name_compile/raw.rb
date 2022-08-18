# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module Raw
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: Tms::NameCompile.sources,
                destination: :name_compile__raw
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Append::NilFields, fields: Tms::NameCompile.multi_source_normalizer.get_fields
              transform Rename::Field, from: Tms::Constituents.preferred_name_field, to: :name 
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituentid contype name relation_type termsource],
                target: :fingerprint,
                sep: ' ',
                delete_sources: false
              transform Cspace::NormalizeForID, source: :name, target: :norm
            end
          end
        end
      end
    end
  end
end
