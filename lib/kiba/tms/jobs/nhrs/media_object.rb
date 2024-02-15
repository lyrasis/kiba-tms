# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module MediaObject
          module_function

          def job
            return unless Tms::MediaXrefs.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :nhrs__media_object
              },
              transformer: xforms
            )
          end

          def sources
            %i[
              media_xrefs__objects
              media_xrefs__obj_rights
            ].select { |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform CombineValues::FullRecord,
                prepend_source_field_name: false,
                delim: "--",
                delete_sources: false,
                target: :index
              transform Deduplicate::Table,
                field: :index,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
