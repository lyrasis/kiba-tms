# frozen_string_literal: true

module Kiba
  module Tms
    module AltNumsTypeCleanupShared
      def clean_fingerprint_fields
        %i[number_type correct_type treatment note]
      end
      module_function :clean_fingerprint_fields

      def cleanup_job_tags(tag)
        [:alt_nums, tag, :cleanup]
      end
      module_function :cleanup_job_tags

      def worksheet_add_fields
        %i[correct_type treatment note]
      end

      def worksheet_field_order
        [:number_type, :correct_type, :treatment, :note,
          collate_fields].flatten
      end

      def occ_fields
        %i[occurrences occs_with_remarks occs_with_begindate
          occs_with_enddate]
      end

      def collate_fields
        [occ_fields, :example_rec_nums, :example_values]
      end

      def collation_delim
        "////"
      end

      def fingerprint_flag_ignore_fields
        %i[number_type]
      end

      def orig_fingerprint_fields
        %i[number_type]
      end

      def final_lookup_on_field
        orig_fingerprint_fields[0]
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

      def cleaned_uniq_post_xforms
        bind = binding

        Kiba.job_segment do
          mod = bind.receiver

          mod.occ_fields.each do |field|
            transform Kiba::Tms::Transforms::SumCollatedOccurrences,
              field: field,
              delim: mod.collation_delim
          end
        end
      end

      def final_post_xforms
        bind = binding

        Kiba.job_segment do
          mod = bind.receiver

          transform Delete::Fields,
            fields: [mod.collate_fields, :fingerprint,
              :clean_fingerprint].flatten
        end
      end
    end
  end
end
