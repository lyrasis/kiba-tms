# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module TitleTypes
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :titletypeid, reader: true
      setting :type_field, default: :titletype, reader: true
      setting :used_in,
        default: [
          "ObjTitles.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
