# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromAssocParentsForCon
          module_function

          def job
            return unless Tms::AssocParents.used? &&
              Tms::AssocParents.for?('Constituents')

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :assoc_parents_for__constituents,
                destination: :name_compile__from_assoc_parents_for_con,
                lookup: :constituents__by_all_norms
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::ExtractNamesFromTable,
                table: 'AssocParents.for_constituents',
                fields: [:childstring]
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: Tms::Constituents.preferred_name_field,
                target: :norm
              transform Merge::MultiRowLookup,
                lookup: constituents__by_all_norms,
                keycolumn: :norm,
                fieldmap: {contype: :contype},
                conditions: ->(_r, rows){ [rows.first] }
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :contype
            end
          end
        end
      end
    end
  end
end
