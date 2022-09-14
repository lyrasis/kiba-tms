# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module ForObjects
          extend Tms::Mixins::ForTable
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__alt_nums,
                destination: :alt_nums__for_objects
              },
              transformer: xforms(table: 'Objects')
            )
          end
        end
      end
    end
  end
end
