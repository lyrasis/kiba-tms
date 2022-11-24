# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module OneToOneAcq
        module AcqObjRel
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :one_to_one_acq__combined,
                destination: :one_to_one_acq__acq_obj_rel,
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

              transform Delete::FieldsExcept,
                fields: %i[objectnumber combined]

              if config.row_treatment == :separate
                transform Copy::Field,
                  from: :objectnumber,
                  to: :item1_id
              else
                transform Merge::MultiRowLookup,
                  lookup: one_to_one_acq__acq_num_lookup,
                  keycolumn: :combined,
                  fieldmap: {item1_id: :acqrefnum}
              end

              transform Rename::Fields, fieldmap: {
                objectnumber: :item2_id
              }

              transform Merge::ConstantValues, constantmap: {
                item1_type: 'acquisitions',
                item2_type: 'collectionobjects'
              }

              transform Delete::Fields, fields: :combined
            end
          end
        end
      end
    end
  end
end
