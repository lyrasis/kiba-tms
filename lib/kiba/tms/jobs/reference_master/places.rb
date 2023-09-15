# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module Places
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__prep_clean,
                destination: :reference_master__places
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :placepublished
              transform Delete::FieldsExcept,
                fields: :placepublished
              transform Explode::RowsFromMultivalField,
                field: :placepublished,
                delim: Tms.delim
              transform Clean::StripFields,
                fields: :placepublished
              transform do |row|
                row[:orig_combined] = "placepublished: #{row[:placepublished]}"
                row
              end
            end
          end
        end
      end
    end
  end
end
