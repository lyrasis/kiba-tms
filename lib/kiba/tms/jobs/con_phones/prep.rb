# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConPhones
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_phones,
                destination: :prep__con_phones,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[names__by_constituentid]
            base << :prep__phone_types if Tms::PhoneTypes.used?
            base.select{ |job| Tms.job_output?(job) }
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

              if Tms::PhoneTypes.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__phone_types,
                  keycolumn: :phonetypeid,
                  fieldmap: { phonetype: :phonetype }
              end
              transform Delete::Fields, fields: :phonetypeid

              transform config.description_cleaner if config.description_cleaner

              transform Merge::MultiRowLookup,
                lookup: names__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {
                  matches_constituent: :constituentid,
                  person: :person,
                  org: :org,
                  prefname: :prefname
                }
              transform Tms::Transforms::Constituents::AddRetentionFlag,
                field: :prefname
              transform Delete::Fields, fields: :prefname

              transform Tms::Transforms::ConPhones::SeparatePhoneAndFax
              transform Tms::Transforms::Constituents::PrefixMergeTableDescription,
                fields: %i[phone fax]
              transform Delete::Fields, fields: :conphoneid
            end
          end
        end
      end
    end
  end
end
