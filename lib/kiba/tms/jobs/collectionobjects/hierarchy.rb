# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Collectionobjects
        module Hierarchy
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :associations_reportable_for__objects,
                destination: :collectionobjects__hierarchy
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :relationtype,
                value: "Parent/Child"
              transform Delete::FieldsExcept,
                fields: %i[val1 val2]
              transform Rename::Fields, fieldmap: {
                val1: :broader_object_number,
                val2: :narrower_object_number
              }
              transform CombineValues::FullRecord
              transform Deduplicate::Table,
                field: :index,
                delete_field: true

              unless Tms.migration_status == :prod
                lkup = Tms.get_lookup(
                  jobkey: :collectionobjects__for_ingest,
                  column: :objectnumber
                )
                %w[broader narrower].each do |item|
                  keycol = "#{item}_object_number".to_sym
                  target = "#{item}_in_sample".to_sym
                  transform Merge::MultiRowLookup,
                    lookup: lkup,
                    keycolumn: keycol,
                    fieldmap: {target => :objectnumber}
                  transform FilterRows::FieldPopulated,
                    action: :keep,
                    field: target
                  transform Delete::Fields,
                    fields: target
                end
              end
            end
          end
        end
      end
    end
  end
end
