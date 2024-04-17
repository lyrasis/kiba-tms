# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module LoanoutValuation
          module_function

          def job
            config.config.rectype1 = "Loansout"
            config.config.rectype2 = "Valuationcontrols"
            config.config.sample_from = :rectype1
            config.config.job_xforms = xforms

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__loan_obj_xrefs,
                destination: :nhrs__loanout_valuation,
                lookup: :valuationcontrols__all
              },
              transformer: config.transformers
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[loannumber loantype insurancevalueid]
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  !row[:insurancevalueid].blank? && row[:loantype] == "loan out"
                end

              transform Rename::Field,
                from: :loannumber,
                to: :item1_id
              transform Merge::MultiRowLookup,
                lookup: valuationcontrols__all,
                keycolumn: :insurancevalueid,
                fieldmap: {item2_id: :valuationcontrolrefnumber}
              transform Delete::FieldsExcept,
                fields: %i[item1_id item2_id]
            end
          end
        end
      end
    end
  end
end
