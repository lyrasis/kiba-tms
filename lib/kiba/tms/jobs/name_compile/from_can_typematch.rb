# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromCanTypematch
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_alt_names,
                destination: :name_compile__from_can_typematch
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::SelectCanTypematch

              transform Merge::ConstantValue, target: :termsource, value: 'TMS ConAltNames.typematch'
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[altnameid mainconid],
                target: :constituentid,
                sep: '.',
                delete_sources: true

              transform Tms::Transforms::NameCompile::DetermineTypematchTreatment
            end
          end
        end
      end
    end
  end
end
