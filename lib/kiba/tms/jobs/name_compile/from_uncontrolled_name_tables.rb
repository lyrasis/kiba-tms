# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromUncontrolledNameTables
          module_function

          def job
            return unless Tms::NameCompile.used?
            return if target_tables.empty?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: sources,
                destination: :name_compile__from_uncontrolled_name_tables,
                lookup: lookups
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def sources
            target_tables
              .map{ |key| Tms.const_get(key) }
              .map{ |mod| "name_compile_from__#{mod.filekey}".to_sym }
          end

          def lookups
            base = %i[
                      constituents__by_nonpref_norm
                      constituents__by_norm
                     ]
            if ntc_needed?
              base << :name_type_cleanup__for_uncontrolled_name_tables
            end
            base
          end

          def target_tables
            config.uncontrolled_name_source_tables
              .keys
              .select{ |key| ntc_targets.any?(key) }
          end

          def ntc_needed?
            return false unless ntc_done?

            !target_tables.empty?
          end
          extend Tms::Mixins::NameTypeCleanupable

          def xforms
            bind = binding

            Kiba.job_segment do
              cleanable = bind.receiver.send(:ntc_needed?)
              prefname = Tms::Constituents.preferred_name_field

              transform Tms::Transforms::NameTypeCleanup::ExtractIdSegment,
                target: :orignameval,
                segment: :name
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :orignameval,
                target: :constituentid
              transform Delete::Fields, fields: :orignameval
              transform Deduplicate::Table, field: :constituentid
              transform Merge::ConstantValue,
                target: :termsource,
                value: 'Uncontrolled'

              [constituents__by_nonpref_norm,
               constituents__by_norm].each do |lkup|
                transform Merge::MultiRowLookup,
                  lookup: lkup,
                  keycolumn: :constituentid,
                  fieldmap: {
                    concontype: :contype,
                    conprefname: prefname
                  }
                transform do |row|
                  contype = row[:contype]
                  next row unless contype.blank?

                  conpref = row[:conprefname]
                  next row if conpref.blank?

                  row[prefname] = row[:conprefname]
                  row[:contype] = row[:concontype]
                  row
                end
                transform Delete::Fields, fields: %i[concontype conprefname]
              end



              # if cleanable
              #   transform Tms::Transforms::NameTypeCleanup::OverlayAll,
              #     lookup: name_type_cleanup__for_uncontrolled_name_tables
              # end
            end
          end
        end
      end
    end
  end
end
