# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        extend self

        ACTIVE = {
          '1' => 'active',
          '0' => 'inactive'
        }
        PUBLIC = {
          '1' => 'yes',
          '0' => 'no'
        }
        EXTERNAL = {
          '1' => 'Offsite',
          '0' => 'Local'
        }

        def prep
          xforms = Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::EmptyFields,
              consider_blank: {
                unitheightcm: '.0000',
                unitwidthcm: '.0000',
                unitdepthcm: '.0000',
                securitycode: '0',
              }

            transform Delete::FieldValueMatchingRegexp, fields: %i[site], match: '^\([Nn]ot [Aa]ssigned\)$'

            # merge in address
            transform Merge::MultiRowLookup,
              lookup: prep__con_address,
              keycolumn: :addressid,
              fieldmap: {
                brief_address: :displayname1,
                address: :displayaddress
              }
            transform Delete::Fields, fields: :addressid
            transform Clean::RegexpFindReplaceFieldVals,
              fields: :address,
              find: '%CR%%CR%',
              replace: ', '

            transform Replace::FieldValueWithStaticMapping, source: :active, target: :termstatus, mapping: ACTIVE
            transform Replace::FieldValueWithStaticMapping,
              source: :publicaccess,
              target: :public_access,
              mapping: PUBLIC
            transform Replace::FieldValueWithStaticMapping,
              source: :external,
              target: :storage_location_authority,
              mapping: EXTERNAL
            transform Delete::Fields, fields: %i[active publicaccess external]
            
            transform Tms::Transforms::Locations::AddLocationName
            transform Tms::Transforms::Locations::AddParent
            transform Rename::Field, from: :locationstring, to: :tmslocationstring
          end
          
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__locations,
              destination: :prep__locations,
              lookup: :prep__con_address
            },
            transformer: xforms
          )
        end
      end
    end
  end
end
