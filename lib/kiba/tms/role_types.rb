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
        "Accession Lot Object Related" => "RegistrationSets",
        "Accession Lot Related" => "AccessionLot",
        "Acquisition Related" => "ObjAccession",
        "Bibliography Related" => "ReferenceMaster",
        "Ex-Collections Related" => "Objects",
        "Exhibitions Related" => "Exhibitions",
        "Incoming Loan Related" => "Loansin",
        "Media Related" => "MediaRenditions",
        "Object Related" => "Objects",
        "Outgoing Loan Related" => "Loansout",
        "Rights Related" => "ObjRights",
        "Shipment Related" => "Shipments",
        "Shipment Step Related" => "ShipmentSteps",
        "Site Related" => "Sites",
        "Text Entry Related" => "TextEntries",
        "Venue Related" => "ExhVenuesXrefs"
      },
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
