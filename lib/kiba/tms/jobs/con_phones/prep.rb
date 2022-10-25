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
            base
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields

              if Tms::PhoneTypes.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__phone_types,
                  keycolumn: :phonetypeid,
                  fieldmap: { phonetype: :phonetype }
              end

              transform Tms::Transforms::Constituents::Merger,
                lookup: names__by_constituentid,
                keycolumn: :constituentid,
               targets: {
                  person: :person,
                  org: :org,
                  prefname: :prefname
                }
             transform Tms::Transforms::Constituents::AddRetentionFlag,
               field: :prefname

              transform do |row|
                desc = row[:description]
                next row if desc.blank?

                if desc =~ /^phone$/i
                  row[:description] = nil
                elsif desc =~ /^business|business phone|phone - organization|work$/i
                  row[:description] = nil
                  row[:phonetype] = 'business'
                elsif desc =~ /^cell|phone - cell|phone cell$/i
                  row[:description] = nil
                  row[:phonetype] = 'mobile'
                elsif desc =~ /^home|home phone|phone - home$/i
                  row[:description] = nil
                  row[:phonetype] = 'home'
                end
                row
              end

              transform Tms::Transforms::ConPhones::SeparatePhoneAndFax
              transform Tms::Transforms::Constituents::PrefixMergeTableDescription,
                fields: %i[phone fax]
              transform Delete::Fields, fields: %i[conphoneid phonetypeid]
            end
          end
        end
      end
    end
  end
end
