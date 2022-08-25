# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromObjAccession
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :tms__obj_accession,
                destination: :name_compile__from_obj_accession
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::ExtractNamesFromTable,
                table: 'ObjAccession',
                fields: %i[authorizer initiator]
            end
          end
        end
      end
    end
  end
end
