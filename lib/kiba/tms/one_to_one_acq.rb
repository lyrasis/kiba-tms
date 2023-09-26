# frozen_string_literal: true

module Kiba
  module Tms
    module OneToOneAcq
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :one_to_one_acq__obj_rows,
        reader: true
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[acquisitionlotid registrationsetid acquisitionlot
          acquisitionnumber objectid],
        reader: true,
        constructor: proc { |value|
          value << Tms::ObjAccession.delete_fields
          value << Tms.tms_fields
          value.flatten
        }

      # Kiba-compliant transform class(es) to be run at the end of
      #   source_job_key job
      #
      # @return [Array<#process>]
      setting :initial_cleaner,
        default: [],
        reader: true

      # @return [Array<Symbol>] ID and other always-unique fields not treated as
      #   content for reporting, etc.
      setting :non_content_fields,
        default: %i[objectnumber objectvalueid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :acq_ref_num_deriver,
        default: Tms::Transforms::OneToOneAcq::AcqRefNumDeriver,
        reader: true

      # See https://github.com/lyrasis/kiba-tms/blob/main/doc/mapping_options/obj_accessions.adoc#onetoone
      #   for explanation of the available options: :separate, :grouped, and
      #   :grouped_with_id
      #
      # @return [Symbol]
      setting :row_treatment,
        default: :grouped,
        reader: true

      # If `:row_treatment` is something other than `:separate`, we are likely
      #    to derive multiple Acquisition records from
      setting :group_id_uniquifier_separator,
        default: " grp ",
        reader: true

      def select_xform
        Kiba.job_segment do
          transform FilterRows::AnyFieldsPopulated,
            action: :reject,
            fields: %i[acquisitionlotid registrationsetid acquisitionlot
              acquisitionnumber]
          transform FilterRows::FieldPopulated, action: :keep,
            field: :objectid
          unless Tms::OneToOneAcq.initial_cleaner.empty?
            Tms::OneToOneAcq.initial_cleaner.each { |xform| transform xform }
          end
        end
      end
    end
  end
end
