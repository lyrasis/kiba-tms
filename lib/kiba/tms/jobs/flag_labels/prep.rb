# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module FlagLabels
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__flag_labels,
                destination: :prep__flag_labels
              },
              transformer: config.multitable_xforms(binding)
            )
          end
        end
      end
    end
  end
end
