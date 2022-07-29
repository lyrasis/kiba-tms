# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConXrefDetails
      extend Dry::Configurable

      setting :for_loans, reader: true do
        setting :any, default: true, reader: true
        # transform adding a :con_note field
        setting :con_note_builder, default: nil, reader: true
      end
      
      setting :for_objects, reader: true do
        setting :any, default: true, reader: true
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

