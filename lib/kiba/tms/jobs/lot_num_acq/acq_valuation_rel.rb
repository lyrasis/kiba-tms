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
                destination: :lot_num_acq__acq_valuation_rel
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
              transform Rename::Fields, fieldmap: {
                acquisitionlot: :item1_id
              }
              transform Merge::MultiRowLookup,
                lookup: Tms.get_lookup(
                  jobkey: :valuation_control__all,
                  column: :objinsuranceid
                ),
                keycolumn: :objectvalueid,
                fieldmap: {item2_id: :valuationcontrolrefnumber}
              transform Delete::Fields, fields: :objectvalueid
              transform Merge::ConstantValues, constantmap: {
                item1_type: 'acquisitions',
                item2_type: 'valuationcontrols'
              }
            end
          end
        end
      end
    end
  end
end
