# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module LoanInCreditlines
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__objects,
                destination: :objects__loan_in_creditlines,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if Tms::ObjAccession.loaned_object_treatment ==
                :creditline_to_loanin
              base << :loan_obj_xrefs__loanin_obj_lookup
            end
            base
          end

          def xforms
            Kiba.job_segment do
              if Tms::ObjAccession.loaned_object_treatment ==
                  :creditline_to_loanin
                transform Merge::MultiRowLookup,
                  lookup: loan_obj_xrefs__loanin_obj_lookup,
                  keycolumn: :objectid,
                  fieldmap: {loanin: :objectid}
                transform FilterRows::AllFieldsPopulated,
                  action: :keep,
                  fields: %i[loanin creditline]
                transform Delete::FieldsExcept,
                  fields: %i[objectid creditline]
                transform Clean::RegexpFindReplaceFieldVals,
                  fields: :creditline,
                  find: '(%CR%)+',
                  replace: ' '
              end
            end
          end
        end
      end
    end
  end
end
