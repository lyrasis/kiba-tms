# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LoanObjXrefs
        module LoaninObjLookup
          module_function

          def job
            return unless config.used?
            return if Tms::ObjAccession.loaned_object_treatment ==
              :as_acquisitions

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loan_obj_xrefs,
                destination: :loan_obj_xrefs__loanin_obj_lookup,
                lookup: :loans__in_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[loanid objectid]
              transform Merge::MultiRowLookup,
                lookup: loans__in_lookup,
                keycolumn: :loanid,
                fieldmap: {in: :loanid}
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :in
              transform Delete::FieldsExcept,
                fields: :objectid
            end
          end
        end
      end
    end
  end
end
