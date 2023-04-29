# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        class NotKept
          def initialize
            @source = :migration_action
            @merging = Tms::Transforms::Names.to_merge
          end

          # @private
          def process(row)
            action = row[source]
            return unless merging.any?(action)

            row
          end

          private

          attr_reader :source, :merging
        end
      end
    end
  end
end
