# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module Shaped
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_address,
                destination: :con_address__shaped,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:names__by_constituentid]
            if Tms::Countries.used
              base << :prep__countries
            end
            if Tms::AddressTypes.used
              base << :prep__address_types
            end
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :keeping,
                value: "y"
              transform Delete::Fields,
                fields: :keeping

              if config.migrate_inactive &&
                  config.active_note
                transform Replace::FieldValueWithStaticMapping,
                  source: :active,
                  mapping: config.active_mapping
              else
                transform Delete::Fields, fields: :active
              end

              transform Clean::RegexpFindReplaceFieldVals,
                fields: config.address_fields,
                find: '^n\/a$', replace: ""

              contentfields = config.address_fields
                .reject { |field| field.to_s.start_with?("display") }
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: contentfields

              if Tms::Countries.used
                # See config.country_remappings for why we map in orig value
                transform Merge::MultiRowLookup,
                  lookup: prep__countries,
                  keycolumn: :countryid,
                  fieldmap: {
                    init_addresscountry: :country,
                    origcountry: :orig_country
                  }
                transform Append::NilFields,
                  fields: %i[remappedcountry]
                unless config.country_remappings.empty?
                  transform do |row|
                    orig = row[:origcountry]
                    next row if orig.blank?
                    next row unless row[:init_addresscountry].blank?

                    row[:remappedcountry] = config.country_remappings[orig]
                    row
                  end
                end
                transform Kiba::Extend::Transforms::Cspace::AddressCountry,
                  source: :remappedcountry,
                  target: :remappedcountrycode
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[init_addresscountry remappedcountrycode],
                  target: :addresscountry,
                  delim: "",
                  delete_sources: false
              end
              transform Delete::Fields, fields: :countryid

              if Tms::AddressTypes.used
                address_type_target = if config.address_type_handling == :note
                  :addresstypenote
                else
                  :addresstype
                end
                transform Merge::MultiRowLookup,
                  lookup: prep__address_types,
                  keycolumn: :addresstypeid,
                  fieldmap: {address_type_target => :addresstype}
              end
              transform Delete::Fields, fields: :addresstypeid

              {
                shipping: :defaultshipping,
                billing: :defaultbilling,
                mailing: :defaultmailing
              }.each do |type, srcfield|
                treatment = "#{type}_note".to_sym
                mapping = "#{type}_mapping".to_sym

                if config.send(treatment)
                  transform Replace::FieldValueWithStaticMapping,
                    source: srcfield,
                    target: type,
                    mapping: config.send(mapping)
                else
                  transform Delete::Fields, fields: srcfield
                end
              end

              if config.dates_note
                # todo if required - combine into one :address_dates field
              else
                transform Delete::Fields, fields: %i[begindate enddate]
              end

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :displayaddress,
                find: "%CR%%CR%",
                replace: ", "
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :displayaddress,
                find: "%CR%",
                replace: ", "

              # prepare shortname for use in differentiating addresses
              transform do |row|
                val = row[:shortname]
                next row if val.blank?

                if val.end_with?("(")
                  edit = val.delete_suffix(" (")
                elsif val["()"]
                  edit = val.delete_suffix(" ()")
                else
                  match = val.match(/\((.*)\)/)
                  edit = if match
                    match[1] || val
                  else
                    val
                  end
                end

                row[:shortname] = edit
                row
              end

              # rubocop:disable Layout/LineLength
              transform Tms::Transforms::ConAddress::RemoveRedundantAddressLines,
                lookup: names__by_constituentid
              # rubocop:enable Layout/LineLength

              transform Tms::Transforms::ConAddress::ReshapeAddressData

              unless config.migrate_remarks
                transform Delete::Fields, fields: :remarks
              end
              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.note_fields,
                target: :address_notes,
                delim: "; ",
                delete_sources: true
              if config.address_note_handling == :specific
                transform Prepend::FieldToFieldValue,
                  target_field: :address_notes,
                  prepended_field: :shortname,
                  sep: ": "
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituentid addressplace1 addressplace2 city state
                  zipcode addresscountry],
                target: :combined,
                delim: " - ",
                delete_sources: false
              transform Deduplicate::Flag,
                on_field: :combined,
                in_field: :duplicate,
                using: {}
              transform Delete::Fields, fields: :combined
            end
          end
        end
      end
    end
  end
end
