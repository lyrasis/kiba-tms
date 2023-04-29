# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromCanTypematchSeparateNotes
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :name_compile__from_can_typematch_separate,
                destination: :name_compile__from_can_typematch_separate_notes
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              job = :name_compile__from_can_typematch_separate
              treatment = Tms::NameCompile.source_treatment[job]

              transform Copy::Field, from: :altname, to: :altconname
              transform Tms::Transforms::NameCompile::AddRelatedAltNameNote,
                target: treatment
            end
          end
        end
      end
    end
  end
end
