# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module NotesExtracted
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__unique,
                destination: :places__notes_extracted
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.proximity_as_note
                transform Tms::Transforms::SetNoteFromPattern,
                  fields: config.source_fields,
                  patterns: config.proximity_patterns,
                  target: :proximity
              end
              if config.uncertainty_as_note
                transform Tms::Transforms::SetNoteFromPattern,
                  fields: config.source_fields,
                  patterns: config.uncertainty_patterns,
                  target: :uncertainty
              end
              unless config.misc_note_patterns.empty?
                transform Tms::Transforms::SetNoteFromPattern,
                  fields: config.source_fields,
                  patterns: config.misc_note_patterns,
                  target: :misc_note
              end
            end
          end
        end
      end
    end
  end
end
