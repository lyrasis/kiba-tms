# frozen_string_literal: true

module Kiba
  module Tms
    module LinkedSetAcq
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[objectid objectvalueid objectnumber],
        reader: true
      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key,
        default: :linked_set_acq__rows,
        reader: true
      extend Tms::Mixins::Tableable

      def used?
        Tms::ObjAccession.processing_approaches.any?(:linkedset)
      end

      def select_xform
        Kiba.job_segment do
          transform FilterRows::AllFieldsPopulated,
            action: :keep,
            fields: %i[registrationsetid acquisitionlotid]
        end
      end
    end
  end
end
