# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module FromAssocParentsForCon
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :assoc_parents__for_constituents,
                destination: :names__from_assoc_parents_for_con
              },
              transformer: xforms,
              helper: Kiba::Tms::Names.compilation.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: :childstring
              transform Deduplicate::Table, field: :childstring
              transform Rename::Field, from: :childstring, to: Tms::Constituents.preferred_name_field
              transform Merge::ConstantValue, target: :constituenttype, value: "Person"
              transform Merge::ConstantValue, target: :termsource, value: "TMS AssocParents.for_constituents"
              transform Cspace::NormalizeForID, source: Tms::Constituents.preferred_name_field, target: :norm
            end
          end
        end
      end
    end
  end
end
