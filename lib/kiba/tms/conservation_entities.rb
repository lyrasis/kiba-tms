# frozen_string_literal: true

module Kiba
  module Tms
    module ConservationEntities
      extend Dry::Configurable

      module_function

      setting :checkable,
        default: {
          populated_configured: -> { check_populated_configured }
        },
        reader: true

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[identifier sortidentifier displayidentifier],
        reader: true
      setting :empty_fields,
        default: {
          keydetails: [nil, ""],
          environmentalclassificationid: [nil, "", "0"],
          customenvrequirements: [nil, "", "0"],
          requireipm: [nil, "", "0"],
          remarks: [nil, ""],
          referenceremarks: [nil, ""],
          conservationlabconid: [nil, "", "0"],
          environmentalrequirementextid: [nil, "", "0"]
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
        reader: true

      def check_populated_configured
        return unless populated.nil?

        "#{name}: Configure :populated setting"
      end
    end
  end
end
