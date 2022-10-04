# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjAccession
      extend Dry::Configurable
      module_function

      # What to do with accessionvalue data
      # - :valuation_control - VC procedure created, linked to Acquisition
      #   procedure, and each linked object
      setting :accessionvalue_treatment,
        default: :valuation_control,
        reader: true
      # The :valuetype value used in valuation control procedures created from
      #   this and related tables. Only used when :accessionvalue_treatment
      #   = :valuation_control
      setting :accessionvalue_type,
        default: 'Original Value',
        reader: true

      setting :dog_dates_treatment,
        default: :acquisitionnote,
        reader: true

      setting :percentowned_treatment,
        default: :acquisitionprovisos,
        reader: true
      setting :percentowned_prefix,
        default: 'Percent owned: ',
        reader: true

      setting :delete_fields,
        default: %i[currencyamount currencyrate localamount
                    accessionminutes1 accessionminutes2 budget capitalprogram
                    currencyid originalentityid currententityid],
        reader: true,
        constructor: Proc.new{ |value| set_deletes(value) }
      extend Tms::Mixins::Tableable

      # approaches required for creation of CS acquisitions and obj/acq
      #   relations
      #   options: :onetone, :lotnumber, :linkedlot
      #   see: https://github.com/lyrasis/kiba-tms/blob/main/doc/data_preparation_details/acquisitions.adoc
      setting :processing_approaches, default: %i[one_to_one], reader: true

      setting :configurable,
        default: {
          processing_approaches: Proc.new{ set_processing_approaches }
        },
        reader: true

      def set_deletes(value)
        if accessionvalue_treatment == :valuation_control
          value << :accessionvalue
        end
        if dog_dates_treatment == :drop
          value << %i[deedofgiftsentiso deedofgiftreceivediso]
        end
        if percentowned_treatment == :drop
          value << :currpercentownership
        end
        value.flatten
      end
      private :set_deletes

      def set_processing_approaches
        counter = Tms::Services::RowCounter
        approaches = []
        approaches << :onetoone if used &&
          counter.call(:obj_accession__one_to_one) > 0
        approaches << :lotnumber if used &&
          counter.call(:obj_accession__lot_number) > 0
        approaches << :linkedlot if used &&
          counter.call(:obj_accession__linked_lot) > 0
        approaches
      end
      private :set_processing_approaches
    end
  end
end
