# frozen_string_literal: true

module Kiba
  module Tms
    module AssocParents
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields, default: %i[], reader: true
      # setting :delete_fields, default: %i[complete mixed], reader: true
      extend Tms::Mixins::Tableable

      setting :type_field, default: :relationship, reader: true
      setting :type_field_target, default: :association_type, reader: true
      setting :mergeable_value_field, default: :childstring, reader: true
      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
