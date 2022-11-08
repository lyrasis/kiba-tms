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
            Tms::MediaPaths.used? && config.fields.any?{ |f| f.to_s['pathid'] }
          end

          def merges_renditions?
            Tms::MediaRenditions.used?
          end

          def merges_master?
            Tms::MediaMaster.used?
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
              end

              if mod.send(:merges_renditions?)
                rendfm = config.rendition_merge_fields.map{ |f|
                  ["rend_#{f}".to_sym, f]
                }.to_h
                transform Merge::MultiRowLookup,
                  lookup: prep__media_renditions,
                  keycolumn: :renditionid,
                  fieldmap: rendfm
              end

              if mod.send(:merges_master?)
                fm = config.master_merge_fields.map{ |f|
                  ["ms_#{f}".to_sym, f]
                }.to_h
                transform Merge::MultiRowLookup,
                  lookup: prep__media_master,
                  keycolumn: :renditionid,
                  fieldmap: fm
              end
            end
          end
        end
      end
    end
  end
end
