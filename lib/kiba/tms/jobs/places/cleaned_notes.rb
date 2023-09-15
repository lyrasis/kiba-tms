# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module CleanedNotes
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__cleaned_unique,
                destination: :places__cleaned_notes
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: config.worksheet_added_fields
              transform Delete::FieldsExcept,
                fields: [config.worksheet_added_fields, :norm_combineds].flatten
              transform Clean::StripFields,
                fields: :all
              transform Explode::RowsFromMultivalField,
                field: :norm_combineds,
                delim: config.norm_fingerprint_delim
              transform Rename::Field,
                from: :norm_combineds,
                to: :norm_combined
            end
          end
        end
      end
    end
  end
end
