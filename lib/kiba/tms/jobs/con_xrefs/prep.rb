# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConXrefs
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_xrefs,
                destination: :prep__con_xrefs,
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
                  fieldmap: {xref_role_type: rt.type_field}
              end
              transform Delete::Fields, fields: rt.id_field
            end
          end
        end
      end
    end
  end
end
