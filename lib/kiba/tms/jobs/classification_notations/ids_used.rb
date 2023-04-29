# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ClassificationNotations
        module IdsUsed
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :term_master_thes__used_in_xrefs,
                destination: :classification_notations__ids_used
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: :primarycnid
              @deduper = {}
              transform Deduplicate::Flag, on_field: :primarycnid, in_field: :duplicate, using: @deduper
              transform FilterRows::FieldEqualTo, action: :keep, field: :duplicate, value: "n"
              transform Delete::Fields, fields: :duplicate
            end
          end
        end
      end
    end
  end
end
