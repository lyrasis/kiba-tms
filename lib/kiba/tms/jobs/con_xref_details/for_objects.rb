# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConXrefDetails
        module ForObjects
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_xref_details,
                destination: :con_xref_details__for_objects
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep,
                field: :tablename, value: "Objects"
              if Tms::ConXrefDetails.for_objects.assoc_con_note_builder
                transform { |row|
                  Tms::ConXrefDetails.for_objects.assoc_con_note_builder.process(row)
                }
              end
            end
          end
        end
      end
    end
  end
end
