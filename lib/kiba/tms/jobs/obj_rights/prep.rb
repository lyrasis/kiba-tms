# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjRights
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_rights,
                destination: :prep__obj_rights,
                lookup: :prep__obj_rights_types
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              transform Tms.data_cleaner if Tms.data_cleaner

              transform Delete::EmptyFields

              transform Merge::MultiRowLookup,
                lookup: prep__obj_rights_types,
                keycolumn: :objrightstypeid,
                fieldmap: {objrightstype: :objrightstype}
              transform Delete::Fields, fields: :objrightstypeid
            end
          end
        end
      end
    end
  end
end
