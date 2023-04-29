# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module Prep
          module_function

          def job
            return unless config.used?

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
            base << :prep__con_address if Tms::ConAddress.used
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner
              if config.initial_data_cleaner
                transform config.initial_data_cleaner
              end

              if Tms::ConAddress.used
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
                  find: "%CR%%CR%",
                  replace: ", "
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
                mapping: Tms.boolean_active_mapping
              transform Replace::FieldValueWithStaticMapping,
                source: :external,
                target: :storage_location_authority,
                mapping: config.authority_vocab_mapping
              transform Delete::Fields, fields: %i[active external]

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
