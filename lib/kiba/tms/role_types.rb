# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module RoleTypes
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[defaultroleid primaryroleid allowsanonymousaccess],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :roletypeid, reader: true
      setting :type_field, default: :roletype, reader: true
      setting :used_in,
        default: [
          "ConXrefDetails.#{id_field}",
          "Roles.#{id_field}",
          "ConXrefs.#{id_field}"],
        reader: true
      setting :mappings, default: {
        "Accession Lot Object Related" => "RegistrationSets", #CS Acquisition
        "Accession Lot Related" => "AccessionLot", #CS Acquisition
        "Acquisition Related" => "ObjAccession", #CS Acquisition
        "Bibliography Related" => "ReferenceMaster", #CS Citation authority
        "Ex-Collections Related" => "Objects", #CS Object - owner, former owner,
        #  donor, etc.
        "Exhibitions Related" => "Exhibitions", #CS Exhibition
        "Incoming Loan Related" => "Loansin", #CS Loan in
        "Media Related" => "MediaRenditions", #CS Media handling
        "Object Related" => "Objects", #CS Object
        "Outgoing Loan Related" => "Loansout", #CS Loan out
        "Rights Related" => "ObjRights", #CS Object
        "Shipment Related" => "Shipments", #CS Transport (?)
        "Shipment Step Related" => "ShipmentSteps", #CS Transport (?)
        "Site Related" => "Sites", #CS Place authority (?)
        "Text Entry Related" => "TextEntries", #merged into TMS TextEntries
        #  table, which itself is split for merge into different record types
        "Venue Related" => "ExhVenuesXrefs" #CS Exhibition (?)
      },
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
