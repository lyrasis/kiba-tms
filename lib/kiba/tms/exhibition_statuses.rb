# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ExhibitionStatuses
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :exhibitionstatusid, reader: true
      setting :type_field, default: :exhibitionstatus, reader: true
      setting :used_in,
        default: [
          "Exhibitions.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
