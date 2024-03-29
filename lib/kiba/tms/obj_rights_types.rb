# frozen_string_literal: true

module Kiba
  module Tms
    module ObjRightsTypes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :objrightstypeid, reader: true
      setting :type_field, default: :objrightstype, reader: true
      setting :used_in,
        default: ["ObjRights.#{id_field}"],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
