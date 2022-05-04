# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConPhones
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_phones,
                destination: :prep__con_phones,
                lookup: %i[prep__phone_types nameclean__by_constituentid]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Merge::MultiRowLookup,
                lookup: prep__phone_types,
                keycolumn: :phonetypeid,
                fieldmap: { phonetype: :phonetype }
              transform Merge::MultiRowLookup,
                lookup: nameclean__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {
                  matches_constituent: :constituentid,
                  person: :person,
                  org: :org
                }
              transform Tms::Transforms::Constituents::AddRetentionFlag

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
              
              transform Delete::Fields, fields: %i[conphoneid phonetypeid constituentid]
            end
          end
        end
      end
    end
  end
end
