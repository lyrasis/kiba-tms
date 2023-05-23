# frozen_string_literal: true

module Kiba
  module Tms
    module ReferenceMaster
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[alphaheading sortnumber publicaccess
          conservationentityid],
        reader: true
      extend Tms::Mixins::Tableable

      # Used to pass text entry lookup to text_entry_merger if applicable
      setting :text_entry_lookup, default: {}, reader: true
      # Custom transform to merge in text entries
      setting :text_entry_merger, default: nil, reader: true
    end
  end
end
