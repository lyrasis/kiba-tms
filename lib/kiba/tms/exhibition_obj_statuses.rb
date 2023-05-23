# frozen_string_literal: true

module Kiba
  module Tms
    module ExhibitionObjStatuses
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :exhobjectstatusid, reader: true
      setting :type_field, default: :exhobjectstatus, reader: true
      setting :used_in,
        default: [
          "ExhObjXrefs.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
