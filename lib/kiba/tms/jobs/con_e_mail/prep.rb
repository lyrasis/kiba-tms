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
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:names__by_constituentid]
            base << :prep__email_types if Tms::EMailTypes.used
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

              if Tms::EMailTypes.used
                transform Merge::MultiRowLookup,
                  lookup: prep__email_types,
                  keycolumn: :emailtypeid,
                  fieldmap: {emailtype: :emailtype}
              end
              transform Delete::Fields, fields: :emailtypeid

              transform Merge::MultiRowLookup,
                lookup: names__by_constituentid,
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
              transform Tms::Transforms::Constituents::PrefixMergeTableDescription,
                fields: %i[email web]
              transform Delete::Fields,
                fields: %i[conemailid emailtypeid]
            end
          end
        end
      end
    end
  end
end
