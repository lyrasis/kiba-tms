# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LotNumAcq
        module AcqValuationRel
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :lot_num_acq__obj_rows,
                destination: :lot_num_acq__acq_valuation_rel,
                lookup: %i[lot_num_acq__prep
                  acquisitions__ids_final]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  !row[:objectvalueid].blank? && row[:accessionvalue].blank?
                end
              transform Delete::FieldsExcept,
                fields: %i[acquisitionlot objectvalueid]
              transform Merge::MultiRowLookup,
                lookup: lot_num_acq__prep,
                keycolumn: :acquisitionlot,
                fieldmap: {increment: :increment}
              transform Merge::MultiRowLookup,
                lookup: acquisitions__ids_final,
                keycolumn: :increment,
                fieldmap: {item1_id: :acquisitionreferencenumber}
              transform Delete::Fields,
                fields: %i[acquisitionlot increment]

              transform Merge::MultiRowLookup,
                lookup: Tms.get_lookup(
                  jobkey: :valuationcontrols__all,
                  column: :objinsuranceid
                ),
                keycolumn: :objectvalueid,
                fieldmap: {item2_id: :valuationcontrolrefnumber}
              transform Delete::Fields, fields: :objectvalueid
              transform Merge::ConstantValues, constantmap: {
                item1_type: "acquisitions",
                item2_type: "valuationcontrols"
              }
            end
          end
        end
      end
    end
  end
end
