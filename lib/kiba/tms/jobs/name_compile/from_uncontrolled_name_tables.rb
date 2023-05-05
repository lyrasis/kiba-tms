# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromUncontrolledNameTables
          module_function

          def job
            return unless Tms::NameCompile.used?

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
            config.uncontrolled_name_source_tables
              .keys
              .map { |key| Tms.const_get(key) }
              .map { |mod| "name_compile_from__#{mod.filekey}".to_sym }
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

          def ntc_needed?
            return false unless ntc_done?

            ntc_targets.any?("Uncontrolled")
          end
          extend Tms::Mixins::NameTypeCleanupable

          def as_added_source
            Kiba.job_segment do
              prefname = Tms::Constituents.preferred_name_field

              transform do |row|
                next row if row.key?(:name)

                pname = row[prefname]
                row[:name] = pname
                row.delete(prefname)
                row
              end

              transform Deduplicate::Table,
                field: :prefnormorig
            end
          end

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
                value: "Uncontrolled"

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
                transform Copy::Field,
                  from: :constituentid,
                  to: :prefnormorig
              end

              if cleanable
                transform Tms::Transforms::NameTypeCleanup::ExplodeMultiNames,
                  lookup: name_type_cleanup__for_uncontrolled_name_tables

                transform Tms::Transforms::NameTypeCleanup::OverlayAll

                transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                  source: prefname,
                  target: :corrnorm

                dropped = Tms::NameTypeCleanup.dropped_name_indicator
                transform Merge::MultiRowLookup,
                  lookup: Tms.get_lookup(
                    jobkey: :constituents__prep_clean,
                    column: :norm
                  ),
                  keycolumn: :corrnorm,
                  fieldmap: {conpref_contype: :contype},
                  conditions: ->(row, mrows) do
                    return [] unless row[:contype].blank?
                    return [] if row[prefname].blank? ||
                      row[prefname] == dropped

                    [mrows.first]
                  end
                transform Merge::MultiRowLookup,
                  lookup: Tms.get_lookup(
                    jobkey: :constituents__prep_clean,
                    column: :prefnormorig
                  ),
                  keycolumn: :corrnorm,
                  fieldmap: {conorig_contype: :contype},
                  conditions: ->(row, mrows) do
                    return [] unless row[:contype].blank? &&
                      row[:conpref_contype].blank?
                    return [] if row[prefname].blank? ||
                      row[prefname] == dropped

                    [mrows.first]
                  end
                transform Delete::Fields, fields: :corrnorm
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[contype conpref_contype conorig_contype],
                  target: :contype,
                  delim: "",
                  delete_sources: true
                transform do |row|
                  contype = row[:contype]
                  next row unless contype.blank?

                  row[:contype] = Tms::NameTypeCleanup.untyped_treatment
                  row
                end
              end
            end
          end
        end
      end
    end
  end
end
