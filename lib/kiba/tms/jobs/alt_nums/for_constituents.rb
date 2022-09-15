# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module ForConstituents
          extend Tms::Mixins::ForTable
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__alt_nums,
                destination: :alt_nums__for_constituents
              },
              transformer: for_table_xforms(table: 'Constituents')
            )
          end
        end
      end
    end
  end
end
