# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module LotNumAcq
      extend Dry::Configurable

      module_function

      setting :acq_number_treatment,
        default: :acquisitionnote,
        reader: true
      setting :acq_number_prefix,
        default: "Acquisition number value(s): ",
        reader: true

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :lot_num_acq__rows, reader: true
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[acquisitionlotid registrationsetid
          objectid objectnumber
          objectvalueid],
        reader: true,
        constructor: proc { |value|
          value << Tms::ObjAccession.delete_fields
          value << Tms.tms_fields
          value.flatten
        }
      # @return [Array<Symbol>] ID and other always-unique fields not treated as
      #   content for reporting, etc.
      setting :non_content_fields,
        default: %i[acquisitionlot],
        reader: true
      extend Tms::Mixins::Tableable

      def select_xform
        Kiba.job_segment do
          transform FilterRows::AnyFieldsPopulated,
            action: :reject,
            fields: %i[acquisitionlotid registrationsetid]
          transform FilterRows::FieldPopulated, action: :keep,
            field: :acquisitionlot
        end
      end
    end
  end
end
