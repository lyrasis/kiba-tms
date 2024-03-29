# frozen_string_literal: true

module Kiba
  module Tms
    module LinkedLotAcq
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key,
        default: :linked_lot_acq__rows,
        reader: true
      extend Tms::Mixins::Tableable

      def used?
        Tms::ObjAccession.processing_approaches.any?(:linkedlot)
      end

      def select_xform
        Kiba.job_segment do
          transform FilterRows::FieldPopulated,
            action: :reject,
            field: :registrationsetid
          transform FilterRows::FieldPopulated,
            action: :keep,
            field: :acquisitionlotid
        end
      end
    end
  end
end
