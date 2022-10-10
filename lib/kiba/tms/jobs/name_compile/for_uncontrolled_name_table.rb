# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module ForUncontrolledNameTable
          module_function

          def job(mod:)
            return unless Tms::NameCompile.used?
            return unless mod.used?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: source(mod),
                destination: "name_compile_from__#{mod.filekey}".to_sym,
                lookup: lookups(mod)
              },
              transformer: xforms(mod),
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def lookups(mod)
            base = []
            if ntc_needed?(mod)
              base <<cleanup_lookup(mod)
            end
            base
          end

          def cleanup_lookup(mod)
            "name_type_cleanup_for__#{mod.filekey}".to_sym
          end

          def source(mod)
            lkup = Tms::NameCompile.uncontrolled_name_source_tables
            ns = lkup[mod.name.split('::').last]
            "#{ns}__#{mod.filekey}".to_sym
          end

          def ntc_needed?(mod)
            ntc_targets.any?(mod.table_name)
          end
          extend Tms::Mixins::NameTypeCleanupable

          def xforms(mod)
            bind = binding

            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::ExtractNamesFromTable,
                table: mod.table_name,
                fields: mod.name_fields

              if bind.receiver.send(:ntc_needed?, mod)
                transform Tms::Transforms::NameTypeCleanup::OverlayAll,
                  lookup: send(bind.receiver.send(:cleanup_lookup, mod))
              end
            end
          end
        end
      end
    end
  end
end
