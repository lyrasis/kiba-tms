# frozen_string_literal: true

module Kiba
  module Tms
    module ObjContext
      extend Dry::Configurable
      module_function

      def non_content_fields
        %i[objcontextid objectid]
      end
      extend Tms::Mixins::Tableable

      setting :date_or_chronology_fields,
        default: %i[reign dynasty period],
        reader: true,
        constructor: ->(value){ value - empty_fields.keys }
      # Transforms to clean individual fields
      # Elements should be transform classes that do not need to be initialized
      #   with arguments
      setting :field_cleaners, default: [], reader: true
    end
  end
end
