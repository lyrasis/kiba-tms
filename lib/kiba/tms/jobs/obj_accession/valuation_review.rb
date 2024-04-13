# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module ValuationReview
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_accession__initial_prep,
                destination: :obj_accession__valuation_review
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              pricefields = %i[accessionvalue currencyamount localamount budget
                suggestedaccvalue]

              transform FilterRows::WithLambda,
                action: :reject,
                lambda: ->(row) do
                  val = row[:objectvalueid]
                  val.blank? || val == "-1"
                end
              transform Tms::Transforms::DeleteEmptyMoney,
                fields: pricefields
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: pricefields
            end
          end
        end
      end
    end
  end
end
