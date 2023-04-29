# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ObjRights
      extend Dry::Configurable

      module_function

      def non_content_fields
        %i[objectid]
      end
      setting :delete_fields,
        default: %i[objrightsid],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
