# frozen_string_literal: true

module Kiba
  module Tms
    module PackageFolderXrefs
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[shortcut rbhistoryfolderid],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
