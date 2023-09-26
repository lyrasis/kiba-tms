# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module OneToOneAcq
        module AcqValuationRel
          module_function

          def job
            return unless config.used?
            return unless Tms::ObjInsurance.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :one_to_one_acq__combined,
                destination: :one_to_one_acq__acq_valuation_rel,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :one_to_one_acq__prep
            base << :acquisitions__ids_final
            unless config.row_treatment == :separate
              base << :one_to_one_acq__acq_num_lookup
            end
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  !row[:objectvalueid].blank? && row[:accessionvalue].blank?
                end

              transform Delete::FieldsExcept,
                fields: %i[objectvalueid objectnumber combined]

              if config.row_treatment == :separate
                transform Rename::Field,
                  from: :objectnumber,
                  to: :refnum
              else
                transform Delete::Fields, fields: :objectnumber
                transform Merge::MultiRowLookup,
                  lookup: one_to_one_acq__acq_num_lookup,
                  keycolumn: :combined,
                  fieldmap: {refnum: :acqrefnum}
              end
              transform Merge::MultiRowLookup,
                lookup: one_to_one_acq__prep,
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
                  jobkey: :valuation_control__all,
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
