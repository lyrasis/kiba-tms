# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromAssocParentsForCon
          module_function

          def job
            return unless Tms::AssocParents.used?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :assoc_parents__for_constituents,
                destination: :name_compile__from_assoc_parents_for_con
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
            end
          end
        end
      end
    end
  end
end
