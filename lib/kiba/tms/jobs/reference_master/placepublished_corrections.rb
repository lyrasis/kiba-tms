# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module PlacepublishedCorrections
          module_function

          def job
            return unless config.placepublished_done

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__placepublished_returned_compile,
                destination: :reference_master__placepublished_corrections
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :corrected
              transform Rename::Field,
                from: :publisher,
                to: :publisherorganizationlocal
            end
          end
        end
      end
    end
  end
end
