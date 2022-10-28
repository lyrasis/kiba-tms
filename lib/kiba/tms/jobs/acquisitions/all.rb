# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module All
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :acquisitions__all
              },
              transformer: xforms
            )
          end

          def sources
            base = []
            if Tms::LinkedSetAcq.used?
              base << :acquisitions__from_linked_set
            end
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Append::NilFields,
                fields: config.multisource_normalizer.get_fields
            end
          end
        end
      end
    end
  end
end
