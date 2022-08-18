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
              transform Delete::FieldsExcept, fields: %i[approver handler requestedby]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[approver handler requestedby], target: :combined,
                sep: '|||', delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Delete::FieldsExcept, fields: :combined
              transform Explode::RowsFromMultivalField, field: :combined, delim: '|||'
              transform Deduplicate::Table, field: :combined
              transform Rename::Field, from: :combined, to: Tms::Constituents.preferred_name_field
              transform Merge::ConstantValue, target: :termsource, value: 'TMS ObjLocations'
              transform Merge::ConstantValue, target: :relation_type, value: '_main term'
            end
          end
        end
      end
    end
  end
end
