# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConservationEntities
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[identifier sortidentifier displayidentifier],
        reader: true
      setting :empty_fields,
        default: {
          :keydetails=>[nil, ""],
          :environmentalclassificationid=>[nil, "", "0"],
          :customenvrequirements=>[nil, "", "0"],
          :requireipm=>[nil, "", "0"],
          :remarks=>[nil, ""],
          :referenceremarks=>[nil, ""],
          :conservationlabconid=>[nil, "", "0"],
          :environmentalrequirementextid=>[nil, "", "0"]
        },
        reader: true
      extend Tms::Mixins::Tableable

      extend Tms::Mixins::MultiTableMergeable

      setting :base_fields,
        default: %i[conservationentityid id tableid],
        reader: true
      # whether conservation entity data has actually been used/augmented (true)
      #   or whether it looks like the default field data had been created
      #   automatically by TMS (false)
      setting :populated,
        default: nil,
        reader: true,
        constructor: proc{ set_populated }

     def set_populated
        return false if (fields - base_fields).empty?

        true
      end
    end
  end
end
