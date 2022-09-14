# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjAccession
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      module_function

      setting :configurable,
        default: {
          processing_approaches: Proc.new{ set_processing_approaches }
        },
        reader: true
      # The first three rows are fields all marked as not in use in the TMS data dictionary
      setting :delete_fields,
        default: %i[currencyamount currencyrate localamount
                    accessionminutes1 accessionminutes2 budget capitalprogram
                    currencyid originalentityid currententityid],
        reader: true
      setting :empty_fields, default: {}, reader: true
      # approaches required for creation of CS acquisitions and obj/acq relations
      #   options: :onetone, :lotnumber, :linkedlot
      #   see: https://github.com/lyrasis/kiba-tms/blob/main/doc/data_preparation_details/acquisitions.adoc
      setting :processing_approaches, default: %i[one_to_one], reader: true

      def set_processing_approaches
        counter = Tms::Services::RowCounter
        approaches = []
        approaches << :onetoone if used && counter.call(:obj_accession__one_to_one) > 0
        approaches << :lotnumber if used && counter.call(:obj_accession__lot_number) > 0
        approaches << :linkedlot if used && counter.call(:obj_accession__linked_lot) > 0
        approaches
      end
    end
  end
end
