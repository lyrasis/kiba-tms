# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_address,
                destination: :prep__con_address,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:names__by_constituentid]
            if Tms::AddressTypes.used
              base << :tms__address_types
            end
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              transform Merge::MultiRowLookup,
                lookup: names__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {matches_constituent: :constituentid}

              if Tms::AddressTypes.used
                transform Merge::MultiRowLookup,
                  lookup: tms__address_types,
                  keycolumn: :addresstypeid,
                  fieldmap: {addresstype: :addresstype}
              end

              transform Tms::Transforms::ConAddress::AddRetentionFlag
            end
          end
        end
      end
    end
  end
end
