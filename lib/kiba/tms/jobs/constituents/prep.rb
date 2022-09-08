# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__constituents,
                destination: :prep__constituents,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[prep__con_types]
            base << :con_dates__to_merge if Tms::Constituents.dates.merging
            base
          end
          
          def xforms
            Kiba.job_segment do
              prefname = Tms::Constituents.preferred_name_field
              
              transform Tms::Transforms::DeleteTmsFields

              empty_fields = Tms::Constituents.empty_fields
              unless empty_fields.empty?
                empty_fields.each do |field|
                  transform Warn::UnlessFieldValueMatches, field: field, match: '^0|$', matchmode: :regexp
                end
              end

              to_del = Tms::Constituents.omitted_fields
              unless to_del.empty?
                transform Delete::Fields, fields: to_del
              end
              
              transform Delete::FieldValueContainingString, fields: %i[defaultdisplaybioid], match: '-1'
              
              transform Merge::MultiRowLookup,
                keycolumn: :constituenttypeid,
                lookup: prep__con_types,
                fieldmap: {constituenttype: :constituenttype}
              transform Delete::Fields, fields: :constituenttypeid

              if Tms::Constituents.prep_transform_pre
                transform Tms::Constituents.prep_transform_pre
              end
              
              transform Replace::FieldValueWithStaticMapping,
                source: :constituenttype,
                target: :constituenttype,
                mapping: Tms::Constituents.type_mapping,
                fallback_val: :orig,
                delete_source: false
              transform Tms::Transforms::Constituents::DeriveType
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituenttype derivedcontype],
                target: :contype,
                sep: '',
                delete_sources: false
              transform Copy::Field, from: :contype, to: :contype_norm
              transform Tms::Transforms::Constituents::NormalizeContype
              
              # # not used by anything?
              # transform CombineValues::FromFieldsWithDelimiter,
              #   sources: [:contype_norm, prefname],
              #   target: :combined,
              #   sep: ' ',
              #   delete_sources: false
              # transform Deduplicate::FlagAll, on_field: :combined, in_field: :duplicate, explicit_no: false
              # transform Delete::Fields, fields: :combined

              # remove institution value if it is the same as what is in preferred name field
              transform Delete::FieldValueIfEqualsOtherField,
                delete: :institution,
                if_equal_to: prefname,
                casesensitive: false

              # remove non-preferred form name value if it is the same as what is in preferred name field
              transform Delete::FieldValueIfEqualsOtherField,
                delete: Tms::Constituents.var_name_field,
                if_equal_to: prefname,
                casesensitive: false

              # remove institution value if it is the same as non-preferred form name value
              transform Delete::FieldValueIfEqualsOtherField,
                delete: :institution,
                if_equal_to: Tms::Constituents.var_name_field,
                casesensitive: false

              transform Tms::Transforms::Constituents::FlagInconsistentOrgNames
              transform Tms::Transforms::Constituents::CleanRedundantOrgNameDetails
              
              # tag rows as to whether they do or do not actually contain any name data
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[displayname alphasort lastname firstname middlename institution], target: :namedata,
                sep: '', delete_sources: false

              # remove non-preferred form of name if not including flipped as variant
              unless Tms::Constituents.include_flipped_as_variant
                transform Delete::Fields, fields: Tms::Constituents.var_name_field
              end

              if Tms::Constituents.dates.merging
                transform Merge::MultiRowLookup,
                  lookup: con_dates__to_merge,
                  keycolumn: :constituentid,
                  fieldmap: {birth_foundation_date: :birth_foundation_date}
                transform Merge::MultiRowLookup,
                  lookup: con_dates__to_merge,
                  keycolumn: :constituentid,
                  fieldmap: {death_dissolution_date: :death_dissolution_date}
                transform Merge::MultiRowLookup,
                  lookup: con_dates__to_merge,
                  keycolumn: :constituentid,
                  fieldmap: {datenote: :datenote},
                  delim: '%CR%%CR%',
                  sorter: Lookup::RowSorter.new(on: :condateid, as: :to_i)
              end
              
              if Kiba::Tms::Constituents.date_append.to_type == :duplicate
                transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                  source: Tms::Constituents.preferred_name_field,
                  target: :norm
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[contype_norm norm],
                  target: :combined,
                  sep: ' ',
                  delete_sources: false
                transform Deduplicate::FlagAll, on_field: :combined, in_field: :duplicate
              end

              unless Kiba::Tms::Constituents.date_append.to_type == :none
                transform Kiba::Tms::Transforms::Constituents::AppendDatesToNames
              end

              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: Tms::Constituents.preferred_name_field,
                target: :norm
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype_norm norm],
                target: :combined,
                sep: ' ',
                delete_sources: false
              transform Deduplicate::FlagAll, on_field: :combined, in_field: :duplicate, explicit_no: false
              transform Delete::Fields, fields: %i[contype_norm]

              boolfields = []
              boolfields << :approved unless Tms::Constituents.map_approved
              boolfields << :active unless Tms::Constituents.map_active
              boolfields << :isstaff unless Tms::Constituents.map_isstaff
              boolfields << :isprivate unless Tms::Constituents.map_isprivate
              unless boolfields.empty?
                transform Delete::Fields, fields: boolfields
              end

              if Tms::Constituents.map_isprivate
                transform Rename::Field, from: :isprivate, to: :is_private_collector
              end
            end
          end
        end
      end
    end
  end
end
