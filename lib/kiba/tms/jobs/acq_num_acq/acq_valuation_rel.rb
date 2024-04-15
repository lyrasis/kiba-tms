# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AcqNumAcq
        module AcqValuationRel
          module_function

          def job
            return unless config.used?
            return unless Tms::ObjInsurance.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :acq_num_acq__obj_rows,
                destination: :acq_num_acq__acq_valuation_rel,
                lookup: %i[acq_num_acq__rows
                  acq_num_acq__prep
                  acquisitions__ids_final]
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              combinefields = [:acquisitionnumber] + config.content_fields

              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  !row[:objectvalueid].blank? && row[:accessionvalue].blank?
                end
              transform CombineValues::FromFieldsWithDelimiter,
                sources: combinefields,
                target: :combined,
                delim: " ",
                delete_sources: true

              transform Delete::FieldsExcept,
                fields: %i[combined objectvalueid]
              transform Merge::MultiRowLookup,
                lookup: acq_num_acq__rows,
                keycolumn: :combined,
                fieldmap: {refnum: :acquisitionreferencenumber}
              transform Merge::MultiRowLookup,
                lookup: acq_num_acq__prep,
                keycolumn: :refnum,
                fieldmap: {increment: :increment}
              transform Merge::MultiRowLookup,
                lookup: acquisitions__ids_final,
                keycolumn: :increment,
                fieldmap: {item1_id: :acquisitionreferencenumber}
              transform Delete::Fields,
                fields: %i[combined refnum increment]
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
