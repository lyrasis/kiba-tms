# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjContext
      extend Dry::Configurable
      module_function

      def non_content_fields
        %i[objcontextid objectid]
      end
      extend Tms::Mixins::Tableable

      # Transforms to clean individual fields
      # Elements should be transform classes that do not need to be initialized
      #   with arguments
      setting :field_cleaners, default: [], reader: true
    end
  end
end
