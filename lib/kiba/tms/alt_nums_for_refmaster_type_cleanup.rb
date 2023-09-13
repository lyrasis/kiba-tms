# frozen_string_literal: true

module Kiba
  module Tms
    module AltNumsForRefmasterTypeCleanup
      module_function

      extend Dry::Configurable

      setting :base_job,
        default: :alt_nums__types_for_reference_master,
        reader: true

      setting :fingerprint_fields,
        default: %i[number_type correct_type treatment note],
        reader: true

      extend Kiba::Extend::Mixins::IterativeCleanup

      setting :orig_fingerprint_fields,
        default: %i[number_type],
        reader: true

      def job_tags
        %i[alt_nums reference_master cleanup]
      end

      def worksheet_add_fields
        %i[correct_type treatment note]
      end

      def worksheet_field_order
        %i[number_type correct_type treatment note
          occurrences occs_with_remarks occs_with_begindate
          occs_with_enddate
          example_rec_nums example_values]
      end

      def fingerprint_flag_ignore_fields
        %i[number_type]
      end

      def base_job_cleaned_pre_xforms
        bind = binding

        Kiba.job_segment do
          mod = bind.receiver

          transform Fingerprint::Add,
            target: :fingerprint,
            fields: mod.orig_fingerprint_fields
        end
      end
    end
  end
end
