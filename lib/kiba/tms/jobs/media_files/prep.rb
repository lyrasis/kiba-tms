# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__media_files,
                destination: :prep__media_files,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if merges_paths?
              base << :prep__media_paths
            end
            if merges_renditions?
              base << :prep__media_renditions
            end
            if merges_master?
              base << :prep__media_master
            end
            base
          end

          def merges_paths?
            Tms::MediaPaths.used? && config.fields.any?(Tms::MediaPaths.id_field)
          end

          def merges_renditions?
            Tms::MediaRenditions.used? && config.fields.any?(:renditionid)
          end

          def merges_master?
            Tms::MediaMaster.used? && config.fields.any?(:renditionid)
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              mod = bind.receiver
              config = mod.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if mod.send(:merges_paths?)
                transform Merge::MultiRowLookup,
                  lookup: prep__media_paths,
                  keycolumn: :pathid,
                  fieldmap: {path: Tms::MediaPaths.type_field}
              else
                transform Append::NilFields, fields: :path
              end

              # move any path info out of :filename and onto end of :path
              transform do |row|
                filename = row[:filename]
                next row if filename.blank?
                next row unless filename["\\"]

                path = row[:path] ||= ""
                parts = filename.split("\\")
                filename = parts.pop

                row[:filename] = filename
                row[:path] = [path, parts].flatten
                  .join("\\")
                row
              end

              transform Deduplicate::FlagAll,
                on_field: :filename,
                in_field: :duplicate_filename,
                explicit_no: false
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[path filename],
                target: :fullpath,
                delim: "/",
                delete_sources: false
              transform Deduplicate::FlagAll,
                on_field: :fullpath,
                in_field: :duplicate_fullpath,
                explicit_no: false

              if mod.send(:merges_renditions?)
                rendfm = config.rendition_merge_fields.map { |f|
                  ["rend_#{f}".to_sym, f]
                }.to_h
                transform Merge::MultiRowLookup,
                  lookup: prep__media_renditions,
                  keycolumn: :renditionid,
                  fieldmap: rendfm
              end

              if mod.send(:merges_master?)
                fm = config.master_merge_fields.map { |f|
                  ["ms_#{f}".to_sym, f]
                }.to_h
                transform Merge::MultiRowLookup,
                  lookup: prep__media_master,
                  keycolumn: :renditionid,
                  fieldmap: fm
              end

              transform Delete::Fields,
                fields: %i[pathid]
              transform Delete::EmptyFields
            end
          end
        end
      end
    end
  end
end
