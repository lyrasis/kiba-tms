# frozen_string_literal: true

module Tms
  module Transforms
    module TextEntries
      class ForConditionsPrepper
        include Tms::Transforms::ValueCombiners

        def initialize(notefield: :text_entry)
          @notefield = notefield
        end

        def process(row)
          row[notefield] = attributed(row)
          row
        end

        private

        attr_reader :notefield

        def prefix_source_fields
          [:purpose]
        end

        def body_source_fields
          [:textentry]
        end
      end
    end
  end
end
