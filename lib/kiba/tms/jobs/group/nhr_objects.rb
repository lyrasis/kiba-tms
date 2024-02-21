# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Group
        module NhrObjects
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__package_list,
                destination: :group__nhr_objects
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[orderpos package objectnumber]
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :objectnumber
              transform Rename::Fields, fieldmap: {
                objectnumber: :item1_id,
                package: :item2_id
              }
              transform Merge::ConstantValues,
                constantmap: {
                  item1_type: "collectionobjects",
                  item2_type: "groups"
                }
              transform Sort::ByFieldValue,
                field: :orderpos,
                order: :desc
              transform Delete::Fields,
                fields: :orderpos
              transform CombineValues::FullRecord,
                prepend_source_field_name: true,
                delim: "--",
                delete_sources: false,
                target: :index
              transform Deduplicate::Table,
                field: :index,
                delete_field: true
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
