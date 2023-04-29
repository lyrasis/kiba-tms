# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ConXrefs
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[displayed isdefaultdisplaybio],
        reader: true
      setting :empty_fields,
        default: {
          conxrefsetid: [nil, "", "-1", "0"]
        },
        reader: true
      extend Tms::Mixins::Tableable

      setting :for_loans, reader: true do
        # transform adding a :con_note field
        setting :con_note_builder, default: nil, reader: true
      end

      setting :for_objects, reader: true do
        # transform adding an `:assoc_con_note` field
        setting :assoc_con_note_builder, default: nil, reader: true
        # list of con_xref roles controlling merge into assoc person/org field of object record
        setting :assoc_con_roles, default: %w[], reader: true
        # list of con_xref roles controlling merge into objectproduction person/org field
        #   of object record
        setting :production_con_roles, default: %w[], reader: true
      end
    end
  end
end
