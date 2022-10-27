# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LinkedSetAcq
        module ObjectStatuses
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :linked_set_acq__obj_rows,
                destination: :linked_set_acq__object_statuses,
                lookup: :linked_set_acq__prep
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::FieldsExcept,
                fields: %i[objectid registrationsetid]
              transform Merge::MultiRowLookup,
                lookup: linked_set_acq__prep,
                keycolumn: :registrationsetid,
                fieldmap: {objectstatus: :objectstatus}
              transform Delete::Fields,
                fields: :registrationsetid
            end
          end
        end
      end
    end
  end
end
