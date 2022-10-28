# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LotNumAcq
        module Rows
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :lot_num_acq__obj_rows,
                destination: :lot_num_acq__rows,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            unless config.acq_number_treatment == :drop
              base << :lot_num_acq__obj_rows
            end
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Deduplicate::Table,
                field: :acquisitionlot
              unless config.acq_number_treatment == :drop
                transform Merge::MultiRowLookup,
                  lookup: lot_num_acq__obj_rows,
                  keycolumn: :acquisitionlot,
                  fieldmap: {acquisitionnumber: :acquisitionnumber},
                  delim: Tms.delim
                transform Deduplicate::FieldValues,
                  fields: :acquisitionnumber,
                  sep: Tms.delim
                transform Clean::RegexpFindReplaceFieldVals,
                  fields: :acquisitionnumber,
                  find: '\|',
                  replace: ', '
              end
            end
          end
        end
      end
    end
  end
end
