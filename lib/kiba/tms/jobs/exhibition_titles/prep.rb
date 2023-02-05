# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhibitionTitles
        module Prep
          module_function

          def job
            return unless config.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__exhibition_titles,
                destination: :prep__exhibition_titles,
                lookup: :tms__exhibitions
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields,
                  fields: config.omitted_fields
              end
              transform Tms.data_cleaner if Tms.data_cleaner

              transform Merge::MultiRowLookup,
                lookup: tms__exhibitions,
                keycolumn: :exhibitionid,
                fieldmap: {maintitle: :exhtitle}

              transform do |row|
                next if row[:title] == row[:maintitle]

                row
              end

              transform Delete::Fields, fields: :maintitle
            end
          end
        end
      end
    end
  end
end
