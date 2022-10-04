# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConXrefDetails
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_xref_details,
                destination: :prep__con_xref_details,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__role_types if Tms::RoleTypes.used?
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              rt = Tms::RoleTypes

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if rt.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__role_types,
                  keycolumn: rt.id_field,
                  fieldmap: {detail_role_type: rt.type_field}
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.fields - [:conxrefdetailid],
                target: :combined,
                sep: ' ',
                delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true
              transform Delete::Fields, fields: rt.id_field
            end
          end
        end
      end
    end
  end
end
