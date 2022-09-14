# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module TextEntries
      module_function
      extend Tms::Mixins::MultiTableMergeable
      extend Dry::Configurable
      # whether or not table is used
      setting :used, default: ->{ Tms::Table::List.include?('TextEntries') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[complete mixed], reader: true
      setting :target_tables, default: [], reader: true
      # pass in client-specific transform classes to prepare text_entry rows for merging
      setting :for_conditions_transform, default: nil, reader: true
      setting :for_constituents_transform, default: nil, reader: true
      setting :for_exhibitions_transform, default: nil, reader: true
      setting :for_loans_transform, default: nil, reader: true
      setting :for_object_transform, default: nil, reader: true
      setting :for_obj_accession_transform, default: nil, reader: true
      setting :for_obj_components_transform, default: nil, reader: true
      setting :for_obj_context_transform, default: nil, reader: true
      setting :for_obj_deaccession_transform, default: nil, reader: true
      setting :for_obj_rights_transform, default: nil, reader: true
      setting :for_reference_master_transform, default: nil, reader: true
      setting :for_shipments_transform, default: nil, reader: true
      setting :for_shipment_steps_transform, default: nil, reader: true
      setting :for_term_master_thes_transform, default: nil, reader: true
    end
  end
end
