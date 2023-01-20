# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module ToMerge
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_address,
                destination: :con_address__to_merge,
                lookup: %i[
                           prep__countries
                           names__by_constituentid
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :keeping,
                value: 'y'
              transform Delete::Fields,
                fields: %i[kept keeping]
              transform Clean::RegexpFindReplaceFieldVals,
                fields: Tms::Constituents.address_fields,
                find: '^n\/a$', replace: ''

              # SECTION remove rows with no address info
              transform CombineValues::FromFieldsWithDelimiter,
                sources: Tms::Constituents.address_fields,
                target: :concat,
                sep: '',
                delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep,
                field: :concat
              transform Delete::Fields, fields: %i[concat]
              # END SECTION

              transform Merge::MultiRowLookup,
                lookup: prep__countries,
                keycolumn: :countryid,
                fieldmap: {addresscountry: :country}
              transform Delete::Fields, fields: :countryid
              transform Cspace::AddressCountry

              {
                active: :active,
                shipping: :defaultshipping,
                billing: :defaultbilling,
                mailing: :defaultmailing
              }.each do |type, srcfield|
                treatment = "address_#{type}".to_sym
                mapping = "#{type}_mapping".to_sym

                if Tms::Constituents.send(treatment)
                  transform Replace::FieldValueWithStaticMapping,
                    source: srcfield,
                    target: type,
                    mapping: config.send(mapping)
                else
                  transform Delete::Fields, fields: srcfield
                end
              end
              if Tms::Constituents.address_active
                transform Rename::Field, from: :active, to: :addressstatus
              end

              if Tms::Constituents.address_dates
                # todo if required - combine into one :address_dates field
              else
                transform Delete::Fields, fields: %i[begindate enddate]
              end

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :displayaddress,
                find: '%CR%%CR%',
                replace: ', '
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :displayaddress,
                find: '%CR%',
                replace: ', '

              # prepare shortname for use in differentiating addresses
              transform do |row|
                val = row[:shortname]
                next row if val.blank?

                if val.end_with?('(')
                  edit = val.delete_suffix(' (')
                elsif val['()']
                  edit = val.delete_suffix(' ()')
                else
                  match = val.match(/\((.*)\)/)
                  if match
                    edit = match[1] ? match[1] : val
                  else
                    edit = val
                  end
                end

                row[:shortname] = edit
                row
              end

              transform Tms::Transforms::ConAddress::RemoveRedundantAddressLines,
                lookup: names__by_constituentid

              transform Tms::Transforms::ConAddress::ReshapeAddressData

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[remarks address_dates addressstatus shipping billing mailing],
                target: :address_notes,
                sep: '; ',
                delete_sources: true

              if Tms::Constituents.address_remarks_handling == :specific
                transform Prepend::FieldToFieldValue,
                  target_field: :address_notes,
                  prepended_field: :shortname,
                  sep: ': '
              end

              transform Prepend::ToFieldValue, field: :address_notes, value: 'Address note:'
            end
          end
        end
      end
    end
  end
end
