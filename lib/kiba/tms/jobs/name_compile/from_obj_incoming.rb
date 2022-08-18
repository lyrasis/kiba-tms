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
              transform Delete::FieldsExcept, fields: namefields
              transform CombineValues::FromFieldsWithDelimiter,
                sources: namefields,
                target: :combined,
                sep: '|||',
                delete_sources: true
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Explode::RowsFromMultivalField, field: :combined, delim: '|||'
              transform Deduplicate::Table, field: :combined
              transform Rename::Field, from: :combined, to: Tms::Constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource, value: 'TMS ObjIncoming'
              transform Merge::ConstantValue, target: :relation_type, value: '_main term'
            end
          end
        end
      end
    end
  end
end
