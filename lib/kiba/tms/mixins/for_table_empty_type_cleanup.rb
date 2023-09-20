# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Methods used by {MultiTableMergeable} to setup type cleanup for
      #   for-tables listed in `target_table_empty_type_cleanup_needed`
      #
      # ## Required settings
      #
      # - `type_field`
      # - `mergeable_value_field`
      #
      # ## Optional settings
      #
      # - `type_field_target`
      #
      # See {MultiTableMergeable} for full description of these settings
      module ForTableEmptyTypeCleanup
        def self.extended(mod)
          mod.send(:define_for_table_empty_type_cleanup_modules)
        end

        def define_for_table_empty_type_cleanup_modules
          target_table_type_cleanup_needed.each do |table|
            define_for_table_empty_type_cleanup_module(table)
          end
        end
        private :define_for_table_empty_type_cleanup_modules

        def define_for_table_empty_type_cleanup_module(table)
          target = Tms.const_get(table)
          modname = ftetc_mod_name(table)
          return if ftetc_mod_exist?(modname)

          moddef = for_table_empty_type_cleanup_module_string(modname, target)
          Tms.module_eval(moddef, __FILE__, __LINE__)
        end
        private :define_for_table_empty_type_cleanup_module

        def ftetc_mod_name(table)
          "#{parent_mod_name}For#{table}EmptyTypeCleanup"
        end
        private :ftetc_mod_name

        def parent_mod_name
          name.split("::").last
        end
        private :parent_mod_name

        def ftetc_mod_exist?(name)
          Tms.constants.include?(name.to_sym)
        end
        private :ftetc_mod_exist?

        def for_table_empty_type_cleanup_module_string(modname, target)
          <<~MODDEF
            module #{modname}
              module_function
              extend Dry::Configurable

              def base_job
                "#{filekey}_reportable_for__#{target.filekey}_no_type".to_sym
              end

              def fingerprint_fields
                [:#{type_field_target}, :sort, :note]
              end

              extend Kiba::Extend::Mixins::IterativeCleanup

              def job_tags
                [:#{filekey}, :#{target.filekey}, :cleanup,
                 :for_table_empty_type]
              end

              def worksheet_add_fields
                %i[note]
              end

              def worksheet_field_order
              [:targetrecord, :#{mergeable_value_field}, :#{type_field_target},
               :note]
              end

              def orig_fingerprint_fields
                [:sort]
              end

              def final_lookup_on_field
                :fp_sort
              end

              def base_job_cleaned_pre_xforms
                bind = binding

                Kiba.job_segment do
                  mod = bind.receiver

                  transform Fingerprint::Add,
                    target: :fingerprint,
                    fields: mod.orig_fingerprint_fields
                  transform Delete::Fields,
                    fields: %i[sort lookupkey]
                end
              end

              def final_post_xforms
                bind = binding

                Kiba.job_segment do
                  mod = bind.receiver

                  transform Fingerprint::Decode,
                    fingerprint: :fingerprint,
                    source_fields: mod.orig_fingerprint_fields,
                    prefix: "fp"

                  transform Delete::Fields,
                    fields: [:fingerprint, :clean_fingerprint].flatten
                end
              end
            end
          MODDEF
        end
        private :for_table_empty_type_cleanup_module_string
      end
    end
  end
end
