# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjComponents
      extend Dry::Configurable
      # Whether or not ObjComponents is used to record information about actual object components
      #   (sub-objects). Either way TMS provides linkage to Locations through ObjComponents
      setting :actual_components, default: false, reader: true
      # Fields that are removed from migration because they are TMS specific or otherwise cannot be migrated
      setting :out_of_scope_fields,
        default: %i[
                    sortnumber injurisdiction
                   ],
        reader: true
      # These are fields that may need to be handled in the future, but are empty in all known TMS
      #   data sets at present. 
      setting :unhandled_fields,
        default: %i[
                    storagemethodid storageformatid homelevel searchhomecontainer tobecombined
                    readystorage readyexhibit prepcomments costmethodid receiveddate homecrateid
                   ],
        reader: true
      # Any other fields to be deleted
      setting :other_delete_fields, default: [], reader: true
      setting :inventorystatus_fields, default: %i[objcompstatus active], reader: true
      setting :comment_fields, default: %i[storagecomments installcomments], reader: true
    end
  end
end
