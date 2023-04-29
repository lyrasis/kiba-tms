# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjPrep
        module Prep
          module_function

          def job
            return unless config.used?
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_prep,
                destination: :prep__obj_prep,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            %i[]
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
            end
          end
        end
      end
    end
  end
end
