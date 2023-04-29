# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module MediaMaster
        class SetPublishable
          def initialize
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: %i[publicaccess approvedforweb]
            )
            @target = :publishto
            @publishing = Tms.using_public_browser
          end

          def process(row)
            row[target] = "None"
            return row unless publishing

            got = getter.call(row)
            return row if got.blank?

            vals = got.values
            if vals.length == 2 && vals.uniq == ["1"]
              row[target] = "CollectionSpace Public Browser"
            end
            row
          end

          private

          attr_reader :getter, :target, :publishing
        end
      end
    end
  end
end
