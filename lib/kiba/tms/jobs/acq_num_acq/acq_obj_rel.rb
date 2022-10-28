# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AcqNumAcq
        module AcqObjRel
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :acq_num_acq__obj_rows,
                destination: :acq_num_acq__acq_obj_rel,
                lookup: :acq_num_acq__rows
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              combinefields = [:acquisitionnumber] + config.content_fields
              transform CombineValues::FromFieldsWithDelimiter,
                sources: combinefields,
                target: :combined,
                sep: ' ',
                delete_sources: true
              transform Delete::FieldsExcept,
                fields: %i[objectnumber combined]
              transform Merge::MultiRowLookup,
                lookup: acq_num_acq__rows,
                keycolumn: :combined,
                fieldmap: {item1_id: :acquisitionreferencenumber}
              transform Delete::Fields, fields: :combined
              transform Rename::Field,
                from: :objectnumber,
                to: :item2_id
              transform Merge::ConstantValues, constantmap: {
                item1_type: 'acquisitions',
                item2_type: 'collectionobjects'
              }
            end
          end
        end
      end
    end
  end
end
