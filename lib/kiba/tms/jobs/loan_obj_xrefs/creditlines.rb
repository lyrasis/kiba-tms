# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LoanObjXrefs
        module Creditlines
          module_function

          def job
            return unless config.used?
            return unless Tms::ObjAccession.loaned_object_treatment ==
              :creditline_to_loanin

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loan_obj_xrefs,
                destination: :loan_obj_xrefs__creditlines,
                lookup: :objects__loan_in_creditlines
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[loanid objectid]
              transform Merge::MultiRowLookup,
                lookup: objects__loan_in_creditlines,
                keycolumn: :objectid,
                fieldmap: {creditline: :creditline}
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :creditline
              transform Delete::Fields,
                fields: :objectid
              transform CombineValues::FullRecord, target: :combined
              transform Deduplicate::Table,
                field: :combined,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
