# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module IdLookup
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__migrating,
                destination: :media_files__id_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[mediamasterid identificationnumber]
            end
          end
        end
      end
    end
  end
end
