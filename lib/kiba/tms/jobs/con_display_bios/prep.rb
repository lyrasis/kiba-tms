# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConDisplayBios
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_display_bios,
                destination: :prep__con_display_bios
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields

              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[displaybio remarks]

              unless config.migrate_inactive
                transform FilterRows::FieldEqualTo,
                  action: :reject,
                  field: :isactive,
                  value: "0"
              end

              unless config.migrate_non_displayed
                transform FilterRows::FieldEqualTo,
                  action: :reject,
                  field: :isdisplayed,
                  value: "0"
              end

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              if config.cleaner
                transform config.cleaner
              end
            end
          end
        end
      end
    end
  end
end
