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
            base << :one_to_one_acq__prep
            base << :acquisitions__ids_final
            unless config.row_treatment == :separate
              base << :one_to_one_acq__acq_num_lookup
            end
            base << :objects__numbers_cleaned
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::FieldsExcept,
                fields: %i[objectid objectnumber combined]

              if config.row_treatment == :separate
                transform Copy::Field,
                  from: :objectnumber,
                  to: :refnum
              else
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

              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {item2_id: :objectnumber}

              transform Merge::ConstantValues, constantmap: {
                item1_type: "acquisitions",
                item2_type: "collectionobjects"
              }

              transform Delete::Fields,
                fields: %i[combined refnum increment objectnumber objectid]
            end
          end
        end
      end
    end
  end
end
