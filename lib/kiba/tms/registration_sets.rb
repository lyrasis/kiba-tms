# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module RegistrationSets
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[displayorder],
        reader: true,
        constructor: proc { |value| set_deletes(value) }
      setting :non_content_fields,
        default: %i[registrationsetid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :multi_set_lots, default: false, reader: true
      setting :configurable, default: {
                               multi_set_lots: proc {
                                 Tms::Services::RegistrationSets::MultiSetLotChecker.call
                               }
                             },
        reader: true

      setting :con_ref_name_merge_rules,
        default: Tms::ObjAccession.con_ref_name_merge_rules,
        reader: true

      def set_deletes(value)
        if Tms::ObjAccession.dog_dates_treatment == :drop
          value << %i[deedofgiftsentiso deedofgiftreceivediso]
        end
        if Tms::ObjAccession.percentowned_treatment == :drop
          value << :percentowned
        end
        value.flatten
      end
      private :set_deletes
    end
  end
end
