# frozen_string_literal: true

module Kiba
  module Tms
    module UserFields
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[userfieldtype userfielddatatypeid],
        reader: true
      setting :empty_fields,
        default: {},
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
