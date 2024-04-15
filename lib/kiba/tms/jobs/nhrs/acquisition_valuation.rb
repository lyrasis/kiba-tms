# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module AcquisitionValuation
          module_function

          def job
            config.config.rectype1 = "Acquisitions"
            config.config.rectype2 = "Valuationcontrols"
            config.config.sample_from = :rectype1
            config.config.job_xforms = xforms

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_accession__initial_prep,
                destination: :nhrs__acquisition_valuation,
                lookup: %i[
                  nhrs__acquisition_object
                  valuationcontrols__all
                ]
              },
              transformer: config.transformers
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectnumber objectvalueid]
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :objectvalueid

              transform Merge::MultiRowLookup,
                lookup: nhrs__acquisition_object,
                keycolumn: :objectnumber,
                fieldmap: {item1_id: :item1_id}

              transform Merge::MultiRowLookup,
                lookup: valuationcontrols__all,
                keycolumn: :objectvalueid,
                fieldmap: {item2_id: :valuationcontrolrefnumber}
              transform Delete::Fields,
                fields: %i[objectvalueid objectnumber]
            end
          end
        end
      end
    end
  end
end
