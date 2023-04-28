# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module Migratable
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__media_files,
                destination: :media_files__migratable,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:media_files__unmigratable_report]
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              lookups = bind.receiver.send(:lookups)

              if lookups.empty?
                # no unmigratable, pass all through
              else
                transform Merge::MultiRowLookup,
                  lookup: media_files__unmigratable_report,
                  keycolumn: :fileid,
                  fieldmap: {unmigratable: :fileid}
                transform FilterRows::FieldPopulated,
                  action: :reject,
                  field: :unmigratable
                transform Delete::Fields, fields: :unmigratable
              end
            end
          end
        end
      end
    end
  end
end
