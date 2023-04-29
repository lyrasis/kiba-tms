# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        class Kept
          def initialize
            @source = :migration_action
            @keeping = Tms::Transforms::Names.keep_actions
          end

          # @private
          def process(row)
            action = row[source]
            return unless keeping.any?(action)

            row
          end

          private

          attr_reader :source, :keeping
        end
      end
    end
  end
end
