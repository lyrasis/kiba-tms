# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Classifications
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[aatid aatcn sourceid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :classificationid, reader: true
      setting :type_field, default: :classification, reader: true
      setting :used_in,
        default: [
          "ClassificationXRefs.#{id_field}",
          "Objects.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def mappable_type?
        false
      end

      setting :object_merge_fieldmap,
        default: {
          classification: :classification,
          subclassification: :subclassification,
          subclassification2: :subclassification2,
          subclassification3: :subclassification3,
        },
        reader: true
    end
  end
end
