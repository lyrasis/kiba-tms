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
            base = []
            base << :prep__con_types if Tms::ConTypes.used?
            base << :con_dates__to_merge if Tms::Constituents.dates.merging
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              prefname = config.preferred_name_field


              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields,
                  fields: config.omitted_fields
              end

              transform Delete::FieldValueContainingString,
                fields: %i[defaultdisplaybioid],
                match: '-1'

              transform Tms::Transforms::Constituents::PrefFromNonPref

              if Tms::ConTypes.used?
                transform Merge::MultiRowLookup,
                  keycolumn: :constituenttypeid,
                  lookup: prep__con_types,
                  fieldmap: {constituenttype: :constituenttype}
              end
              transform Delete::Fields, fields: :constituenttypeid

              if config.prep_transform_pre
                transform config.prep_transform_pre
              end

              transform Tms::Transforms::Constituents::DeriveType
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituenttype derivedcontype],
                target: :contype,
                sep: '',
                delete_sources: false
              transform Copy::Field, from: :contype, to: :contype_norm
              transform Tms::Transforms::Constituents::NormalizeContype

              # remove institution value if it is the same as what is in
              #   preferred name field
              transform Delete::FieldValueIfEqualsOtherField,
                delete: :institution,
                if_equal_to: prefname,
                casesensitive: false

              # remove non-preferred form name value if it is the same as what
              #   is in preferred name field
              transform Delete::FieldValueIfEqualsOtherField,
                delete: config.var_name_field,
                if_equal_to: prefname,
                casesensitive: false

              # remove institution value if it is the same as non-preferred
              #   form name value
              transform Delete::FieldValueIfEqualsOtherField,
                delete: :institution,
                if_equal_to: config.var_name_field,
                casesensitive: false

              transform Tms::Transforms::Constituents::FlagInconsistentOrgNames
              transform Tms::Transforms::Constituents::CleanRedundantOrgNameDetails

              # tag rows as to whether they do or do not actually contain any
              #   name data
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[displayname alphasort lastname firstname middlename
                            institution],
                target: :namedata,
                sep: '',
                delete_sources: false

              if config.dates.merging
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

              if config.date_append.to_type == :duplicate
                transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                  source: config.preferred_name_field,
                  target: :norm
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[contype_norm norm],
                  target: :combined,
                  sep: ' ',
                  delete_sources: false
                transform Deduplicate::FlagAll,
                  on_field: :combined,
                  in_field: :duplicate
              end

              unless config.date_append.to_type == :none
                transform Kiba::Tms::Transforms::Constituents::AppendDatesToNames
              end

              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: config.preferred_name_field,
                target: :norm
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype_norm norm],
                target: :combined,
                sep: ' ',
                delete_sources: false
              transform Deduplicate::FlagAll,
                on_field: :combined,
                in_field: :duplicate,
                explicit_no: false
              transform Delete::Fields, fields: %i[contype_norm]

              boolfields = []
              boolfields << :approved unless config.map_approved
              boolfields << :active unless config.map_active
              boolfields << :isstaff unless config.map_isstaff
              boolfields << :isprivate unless config.map_isprivate
              unless boolfields.empty?
                transform Delete::Fields, fields: boolfields
              end

              if config.map_isprivate
                transform Rename::Field,
                  from: :isprivate,
                  to: :is_private_collector
              end
            end
          end
        end
      end
    end
  end
end
