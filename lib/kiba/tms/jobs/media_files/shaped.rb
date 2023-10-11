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
                source: :media_files__migratable,
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
                  rend_renditiondate]
              transform Tms::Transforms::DeleteTimestamps,
                fields: :filedate
              transform Rename::Fields, fieldmap: config.rename_field_map
              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.description_sources,
                target: :description,
                delim: "%CR%",
                delete_sources: true

              if config.mediafileuri_generator
                transform config.mediafileuri_generator
              end

              transform Explode::RowsFromMultivalField,
                field: :mediafileuri,
                delim: Tms.delim
            end
          end
        end
      end
    end
  end
end
