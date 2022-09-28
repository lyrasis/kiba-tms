# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjIncoming
      extend Dry::Configurable
      module_function

      setting :non_content_fields,
        default: %i[objincomingid objectid],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
