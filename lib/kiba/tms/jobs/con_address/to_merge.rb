# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module ToMerge
          module_function

          ACTIVE = {
            '0' => 'Inactive address',
            '1' => 'Active address'
          }
          SHIPPING = {
            '0' => nil,
            '1' => 'Is default shipping address'
          }
          BILLING = {
            '0' => nil,
            '1' => 'Is default billing address'
          }
          MAILING = {
            '0' => nil,
            '1' => 'Is default mailing address'
          }

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_address,
                destination: :con_address__to_merge,
                lookup: %i[prep__countries nameclean__by_constituentid]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :keeping, value: 'y'
              transform Delete::Fields, fields: %i[kept keeping conaddressid countryold lastsalestaxid
                                                   addressformatid islocation]

              transform Clean::RegexpFindReplaceFieldVals,
                fields: Tms.constituents.address_fields,
                find: '^n\/a$', replace: ''
              
              # SECTION remove rows with no address info
              transform CombineValues::FromFieldsWithDelimiter,
                sources: Tms.constituents.address_fields,
                target: :concat,
                sep: '',
                delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :concat
              transform Delete::Fields, fields: %i[concat]
              # END SECTION

              transform Merge::MultiRowLookup,
                lookup: prep__countries,
                keycolumn: :countryid,
                fieldmap: {addresscountry: :country}
              transform Delete::Fields, fields: :countryid
              transform Cspace::AddressCountry
              
              if Tms.constituents.address_active
                transform Replace::FieldValueWithStaticMapping, source: :active, target: :addressstatus,
                  mapping: ACTIVE
              else
                transform Delete::Fields, fields: :active
              end

              if Tms.constituents.address_shipping
              transform Replace::FieldValueWithStaticMapping, source: :defaultshipping, target: :shipping,
                mapping: SHIPPING
              else
                transform Delete::Fields, fields: :defaultshipping
              end

              if Tms.constituents.address_billing
              transform Replace::FieldValueWithStaticMapping, source: :defaultbilling, target: :billing,
                mapping: BILLING
              else
                transform Delete::Fields, fields: :defaultbilling
              end

              if Tms.constituents.address_mailing
              transform Replace::FieldValueWithStaticMapping, source: :defaultmailing, target: :mailing,
                mapping: MAILING
              else
                transform Delete::Fields, fields: :defaultmailing
              end

              if Tms.constituents.address_dates
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

              # merge in alphasort and displayname for constituents to prepare for clearing redundant address
              #   lines
              transform Merge::MultiRowLookup,
                lookup: nameclean__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {
                  alphasort: :alphasort,
                  displayname: :displayname,
                  person: :person,
                  org: :org
                }
              transform Tms::Transforms::ConAddress::RemoveRedundantAddressLines
              transform Delete::Fields, fields: %i[alphasort displayname]

              
              transform Tms::Transforms::ConAddress::ReshapeAddressData
              
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[remarks address_dates addressstatus shipping billing mailing],
                target: :address_notes,
                sep: '; ',
                delete_sources: true

              if Tms.constituents.address_remarks_handling == :specific
                transform Prepend::FieldToFieldValue,
                  target_field: :address_notes,
                  prepended_field: :shortname,
                  sep: ': '
              end

              transform Prepend::ToFieldValue, field: :address_notes, value: 'Address note:'

              transform Delete::EmptyFields, consider_blank: {addresstypeid: '0'}
            end
          end
        end
      end
    end
  end
end
