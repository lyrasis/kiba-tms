# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module SurveyTypes
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      extend Tms::Mixins::MultiTableMergeable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :type_lookup, default: true, reader: true
      setting :id_field, default: :surveytypeid, reader: true
      setting :type_field, default: :surveytype, reader: true
      setting :used_in,
        default: [
          "Conditions.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
