# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaRenditions
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__media_renditions,
                destination: :prep__media_renditions,
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
            if merges_statuses?
              base << :prep__media_statuses
            end
            if merges_types?
              base << :prep__media_types
            end
            base
          end

          def merges_paths?
            Tms::MediaPaths.used? && config.fields.any?{ |f| f.to_s['pathid'] }
          end

          def merges_statuses?
            Tms::MediaStatuses.used? && config.fields.any?(:mediastatusid)
          end

          def merges_types?
            Tms::MediaTypes.used? && config.fields.any?(:mediatypeid)
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
                  keycolumn: :thumbpathid,
                  fieldmap: {thumbpath: Tms::MediaPaths.type_field}
              end

              if mod.send(:merges_statuses?)
                transform Merge::MultiRowLookup,
                  lookup: prep__media_statuses,
                  keycolumn: :mediastatusid,
                  fieldmap: {media_rend_status: Tms::MediaStatuses.type_field}
              end

              if mod.send(:merges_types?)
                transform Merge::MultiRowLookup,
                  lookup: prep__media_types,
                  keycolumn: :mediatypeid,
                  fieldmap: {mediatype: Tms::MediaTypes.type_field}
              end
              transform Delete::Fields,
                fields: %i[thumbpathid mediastatusid mediatypeid]

              if Tms::ConRefs.for?('MediaRenditions')
                transform Tms::Transforms::ConRefs::Merger,
                  into: config,
                  keycolumn: :renditionid
              end
            end
          end
        end
      end
    end
  end
end
