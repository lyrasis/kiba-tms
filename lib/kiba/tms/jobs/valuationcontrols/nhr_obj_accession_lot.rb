# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Valuationcontrols
        module NhrObjAccessionLot
          module_function

          def job
            return unless Tms::AccessionLot.used?
            return unless Tms::AccessionLot.has_valuations

            approaches = Tms::ObjAccession.processing_approaches
            return unless approaches.any?(:linkedlot)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_accession__linked_lot,
                destination: :valuationcontrols__nhr_obj_accession_lot,
                lookup: %i[
                  accession_lot__valuation_prep
                  objects__numbers_cleaned
                ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectid acquisitionlotid]
              transform Merge::MultiRowLookup,
                lookup: accession_lot__valuation_prep,
                keycolumn: :acquisitionlotid,
                fieldmap: {item2_id: :valuationcontrolrefnumber}
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :item2_id
              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {item1_id: :objectnumber}
              transform Merge::ConstantValues, constantmap: {
                item1_type: "collectionobjects",
                item2_type: "valuationcontrols"
              }
              transform Delete::Fields,
                fields: %i[objectid acquisitionlotid]
            end
          end
        end
      end
    end
  end
end
