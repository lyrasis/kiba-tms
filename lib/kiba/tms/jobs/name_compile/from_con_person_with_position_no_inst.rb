# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromConPersonWithPositionNoInst
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__for_compile,
                destination: :name_compile__from_con_person_with_position_no_inst
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              job = :name_compile__from_con_person_with_position_no_inst
              treatment = Tms::NameCompile.source_treatment[job]

              transform Tms::Transforms::NameCompile::SelectConPersonWithPositionNoInst

              transform Append::ToFieldValue, field: :constituentid, value: ".position"
              transform Merge::ConstantValue, target: :termsource, value: "TMS Constituents.person_with_position_no_institution"
              transform Rename::Fields, fieldmap: {
                position: :note_text
              }

              if treatment == :bio_note
                transform Merge::ConstantValue, target: :relation_type, value: treatment
              elsif treatment == :name_note
                transform Merge::ConstantValue, target: :relation_type, value: treatment
              elsif treatment == :qualifier
                transform Merge::ConstantValue, target: :relation_type, value: "main term qualifier"
              end
              transform Delete::Fields, fields: Tms::NameCompile.variant_nil
            end
          end
        end
      end
    end
  end
end
