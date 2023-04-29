# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ThesXrefs
        module TermIdsUsed
        module_function
        
        def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__thes_xrefs,
              destination: :thes_xrefs__term_ids_used
            },
            transformer: xforms
          )
        end

        def xforms
          Kiba.job_segment do
            transform Delete::FieldsExcept, fields: :termid
            @deduper = {}
            transform Deduplicate::Flag, on_field: :termid, in_field: :duplicate, using: @deduper
            transform FilterRows::FieldEqualTo, action: :reject, field: :duplicate, value: "y"
            transform Delete::Fields, fields: :duplicate
          end
        end
        end
      end
    end
  end
end
