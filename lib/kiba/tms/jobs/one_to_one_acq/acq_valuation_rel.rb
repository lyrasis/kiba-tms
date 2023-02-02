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
                  to: :item1_id
              else
                transform Delete::Fields, fields: :objectnumber
                transform Merge::MultiRowLookup,
                  lookup: one_to_one_acq__acq_num_lookup,
                  keycolumn: :combined,
                  fieldmap: {item1_id: :acqrefnum}
              end
              transform Delete::Fields, fields: :combined

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
