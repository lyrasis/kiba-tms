# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromObjIncoming
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :tms__obj_incoming,
                destination: :name_compile__from_obj_incoming
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              namefields = %i[approvedby requestedby courierin courierout cratepaidby ininsurpaidby
                              shippingpaidby]
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
