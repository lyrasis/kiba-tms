# frozen_string_literal: true

module Kiba
  module Tms
    module ExhObjXrefs
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[],
        reader: true
      extend Tms::Mixins::Tableable

      # Options: :exhibited_object_information, :drop, :exhibition_planning_note
      # Others may be developed
      setting :text_entry_handling,
        default: :exhibited_object_information,
        reader: true,
        constructor: ->(default) do
                       return :drop if Tms::TextEntries.target_tables.none?(
                         "ExhObjXrefs"
                       )

                       default
                     end
    end
  end
end
