# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module RegistrationSets
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[displayorder],
        reader: true,
        constructor: Proc.new{ |value| set_deletes(value) }
      setting :non_content_fields,
        default: %i[registrationsetid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :multi_set_lots, default: false, reader: true
      setting :configurable, default: {
        multi_set_lots: Proc.new{
          Tms::Services::RegistrationSets::MultiSetLotChecker.call
        }
      },
        reader: true

      setting :con_ref_field_rules,
        default: Tms::ObjAccession.con_ref_field_rules,
        reader: true

      def proviso_sources
        base = []
        if Tms::ObjAccession.dog_dates_treatment == :acquisitionprovisos
          base << %i[deedofgiftsentiso deedofgiftreceivediso]
        end
        if Tms::ObjAccession.percentowned_treatment == :acquisitionprovisos
          base << :percentowned
        end
        base.flatten
      end

      def note_sources
        base = []
        if Tms::ObjAccession.dog_dates_treatment == :acquisitionnote
          base << %i[deedofgiftsentiso deedofgiftreceivediso]
        end
        if Tms::ObjAccession.percentowned_treatment == :acquisitionnote
          base << :percentowned
        end
        base.flatten
      end

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
