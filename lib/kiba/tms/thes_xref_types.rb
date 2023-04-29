# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ThesXrefTypes
      extend Dry::Configurable

      module_function

      setting :delete_fields,
        default: %i[multiselect archivedeletes showguideterms broadesttermfirst
          numlevels primarycnid alwaysdisplayfullpath],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :thesxreftypeid, reader: true
      setting :type_field, default: :thesxreftype, reader: true
      setting :used_in,
        default: [
          "ThesXrefs.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def mappable_type?
        false
      end
    end
  end
end
