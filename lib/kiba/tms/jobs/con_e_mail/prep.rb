# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConEMail
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_email,
                destination: :prep__con_email,
                lookup: %i[prep__email_types nameclean__by_constituentid]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              # merge in email type
              transform Merge::MultiRowLookup,
                lookup: prep__email_types,
                keycolumn: :emailtypeid,
                fieldmap: { emailtype: :emailtype }

              transform Merge::MultiRowLookup,
                lookup: nameclean__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {
                  matches_constituent: :constituentid,
                  person: :person,
                  org: :org
                }
              transform Tms::Transforms::ConEmail::AddRetentionFlag
              transform Tms::Transforms::ConEmail::SeparateEmailAndNonemail

              # clear "email" and "web" values out of description
              transform do |row|
                desc = row[:description]
                next row if desc.blank?

                if desc =~ /^email$/i
                  row[:description] = nil
                elsif desc =~ /^web$/i
                  row[:description] = nil
                end
                row
              end
              transform Tms::Transforms::Constituents::PrefixMergeTableDescription, fields: %i[email web]
              transform Delete::Fields, fields: %i[conemailid emailtypeid constituentid]
            end
          end
        end
      end
    end
  end
end
