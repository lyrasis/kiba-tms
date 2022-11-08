# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module Prep
          module_function

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

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__locations,
                destination: :prep__locations,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__con_address if Tms::ConAddress.used?
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if config.initial_data_cleaner
                transform config.initial_data_cleaner
              end

              if Tms::ConAddress.used?
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
                ba_mappings = config.brief_address_mappings
                unless ba_mappings.empty?
                  transform Replace::FieldValueWithStaticMapping,
                    source: :brief_address,
                    target: :brief_address,
                    mapping: ba_mappings
                end
              end

              transform Replace::FieldValueWithStaticMapping,
                source: :active,
                target: :termstatus,
                mapping: ACTIVE
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
              if config.hierarchy
                transform Tms::Transforms::Locations::AddParent
              end
              transform Rename::Field,
                from: :locationstring,
                to: :tmslocationstring
            end
          end
        end
      end
    end
  end
end
