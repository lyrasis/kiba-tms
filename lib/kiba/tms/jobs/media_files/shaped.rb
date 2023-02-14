# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module Shaped
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__media_files,
                destination: :media_files__shaped
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              mod = bind.receiver
              config = mod.send(:config)

              transform do |row|
                config.post_merge_transforms.each do |xform|
                  xform.process(row)
                end
                row
              end

              transform Delete::Fields,
                fields: %i[filesize memorysize renditionid
                           duplicate_filename duplicate_fullpath
                           rend_thumbpath rend_thumbfilename
                           rend_renditiondate
                          ]
              transform Tms::Transforms::DeleteTimestamps,
                fields: :filedate

              transform Tms::Transforms::IdGenerator,
                prefix: 'MR',
                id_source: :rend_renditionnumber,
                id_target: :identificationnumber,
                sort_on: :filedate,
                sort_type: :date,
                separator: ' '

              transform Rename::Fields, fieldmap: {
                checksum: :checksumvalue,
                filedate: :dategroup,
                ms_publishto: :publishto,
                rend_mediamasterid: :mediamasterid
              }
              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.description_sources,
                target: :description,
                sep: '%CR%',
                delete_sources: true
            end
          end
        end
      end
    end
  end
end
