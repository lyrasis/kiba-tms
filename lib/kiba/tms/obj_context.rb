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
    end
  end
end
