# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module MediaMaster
        class SetPublishable
          def initialize
            @logic = Tms::MediaMaster.publishable_logic
            @target = :publishto
            @publishing = Tms.using_public_browser
          end

          def process(row)
            row[target] = "None"
            return row unless publishing

            publishable = logic.call(row)
            return row unless publishable

            row[target] = "CollectionSpace Public Browser"
            row
          end

          private

          attr_reader :logic, :target, :publishing
        end
      end
    end
  end
end
