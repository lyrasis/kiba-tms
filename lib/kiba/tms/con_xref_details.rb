# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConXrefDetails
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: {}, reader: true

      setting :target_tables, default: [], reader: true
      
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

