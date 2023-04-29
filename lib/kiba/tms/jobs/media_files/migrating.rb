# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module Migrating
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__shaped,
                destination: :media_files__migrating
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              mod = bind.receiver
              config = mod.send(:config)

              unless config.migrate_fileless
                transform FilterRows::FieldPopulated,
                  action: :keep,
                  field: :mediafileuri
              end

              transform Delete::Fields,
                fields: %i[fileid path filename fullpath]

              transform Tms::Transforms::IdGenerator,
                prefix: "MR",
                id_source: :rend_renditionnumber,
                id_target: :identificationnumber,
                sort_on: :filedate,
                sort_type: :date,
                separator: "//"
            end
          end
        end
      end
    end
  end
end
