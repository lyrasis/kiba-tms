# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConXrefDetails
      extend Dry::Configurable

      setting :for_objects, reader: true do
        # transform adding an `:assoc_con_note` field
        setting :assoc_con_note_builder, default: nil, reader: true
        # list of con_xref roles controlling merge into assoc person/org        
        setting :assoc_con_roles, default: %w[], reader: true
        # list of con_xref roles controlling merge into objectproduction person/org
        setting :production_con_roles, default: %w[], reader: true
      end
    end
  end
end

