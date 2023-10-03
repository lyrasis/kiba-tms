# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Methods used by {MultiTableMergeable} to setup type cleanup for
      #   for-tables listed in `target_table_type_cleanup_needed`
      #
      # ## Required settings
      #
      # - `type_field`
      # - `mergeable_value_field`
      #
      # ## Optional settings
      #
      # - `type_field_target`
      # - `additional_occurrence_ct_fields`
      #
      # See {MultiTableMergeable} for full description of these settings
      module ForTableTypeCleanup
        def self.extended(mod)
          mod.send(:define_for_table_cleanup_modules)
        end

        def define_for_table_cleanup_modules
          target_table_type_cleanup_needed.each do |table|
            define_for_table_cleanup_module(table)
          end
        end
        private :define_for_table_cleanup_modules

        def define_for_table_cleanup_module(table)
          target = Tms.const_get(table)
          modname = fttc_mod_name(table)
          return if fttc_mod_exist?(modname)

          moddef = for_table_cleanup_module_string(modname, target)
          Tms.module_eval(moddef, __FILE__, __LINE__)
        end
        private :define_for_table_cleanup_module

        def fttc_mod_name(table)
          "#{parent_mod_name}For#{table}TypeCleanup"
        end
        private :fttc_mod_name

        def parent_mod_name
          name.split("::").last
        end
        private :parent_mod_name

        def fttc_mod_exist?(name)
          Tms.constants.include?(name.to_sym)
        end
        private :fttc_mod_exist?

        def for_table_cleanup_module_string(modname, target)
          <<~MODDEF
            module #{modname}
              module_function
              extend Dry::Configurable

              def base_job
                "#{filekey}_reportable_for__#{target.filekey}_type_occs".to_sym
              end

              def fingerprint_fields
                [:correct_type, :treatment, :note]
              end

              extend Kiba::Extend::Mixins::IterativeCleanup

              def job_tags
                [:#{filekey}, :#{target.filekey}, :cleanup, :type_cleanup]
              end

              def worksheet_add_fields
                %i[correct_type treatment note]
              end

              def occ_fields
                [:occurrences, #{added_occ_fields}]
              end

              def collate_fields
                [occ_fields, :example_rec_ids, :example_values,
                :orig_type_val].flatten
              end

              def collation_delim
                "////"
              end

              def worksheet_field_order
              rev = #{modname}.provided_worksheets.empty? ? nil : :to_review
              [rev, :#{type_field_target}, fingerprint_fields,
               pluralized_collate_fields].flatten
                 .compact
              end

              def fingerprint_flag_ignore_fields
                [:#{type_field_target}]
              end

              def orig_fingerprint_fields
                [:#{type_field_target}]
              end

              def final_lookup_on_field
                :lookupkey
              end

              def pluralized_collate_fields
                collate_fields.map do |field|
                  field.end_with?("s") ? field : (field.to_s. << "s").to_sym
                end
              end
              private :pluralized_collate_fields

              def base_job_cleaned_pre_xforms
                bind = binding

                Kiba.job_segment do
                  mod = bind.receiver

                  transform Rename::Field,
                  from: :#{type_field},
                  to: :#{type_field_target}

                  transform Fingerprint::Add,
                    target: :fingerprint,
                    fields: mod.orig_fingerprint_fields
                end
              end

              def base_job_cleaned_post_xforms
                bind = binding

                Kiba.job_segment do
                  mod = bind.receiver

                  transform Copy::Field,
                  from: :#{type_field_target},
                  to: :orig_type_val
                end
              end

              def cleaned_uniq_post_xforms
                bind = binding

                Kiba.job_segment do
                  mod = bind.receiver

                  mod.occ_fields.each do |field|
                  pf = if field.to_s.end_with?("s")
                         field
                       else
                         ( field.to_s + "s" ).to_sym
                       end
                    transform Kiba::Tms::Transforms::SumCollatedOccurrences,
                      field: pf,
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
          MODDEF
        end
        private :for_table_cleanup_module_string

        def added_occ_fields
          return [] unless respond_to?(:additional_occurrence_ct_fields)

          additional_occurrence_ct_fields.map do |field|
            ":occs_with_#{field}"
          end.join(", ")
        end
        private :added_occ_fields
      end
    end
  end
end
