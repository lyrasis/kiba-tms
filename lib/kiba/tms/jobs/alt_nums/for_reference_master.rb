# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module ForReferenceMaster
          extend ForTableable
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__alt_nums,
                destination: :alt_nums__for_reference_master
              },
              transformer: xforms(table: 'ReferenceMaster')
            )
          end
        end
      end
    end
  end
end
