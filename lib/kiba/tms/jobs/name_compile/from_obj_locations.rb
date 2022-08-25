# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromObjLocations
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :tms__obj_locations,
                destination: :name_compile__from_obj_locations
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              namefields = %i[approver handler requestedby]
              transform Tms::Transforms::NameCompile::ExtractNamesFromTable,
                table: 'ObjIncoming',
                fields: namefields
            end
          end
        end
      end
    end
  end
end
