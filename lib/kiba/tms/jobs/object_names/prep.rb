# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectNames
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__object_names,
                destination: :prep__object_names,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__object_name_types if Tms::ObjectNameTypes.used?
            base << :prep__dd_languages if Tms::DDLanguages.used?
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              langs = Tms::DDLanguages
              types = Tms::ObjectNameTypes

              if config.fields.any?(:active)
                unless config.migrate_inactive
                  transform FilterRows::FieldEqualTo,
                    action: :reject,
                    field: :active,
                    value: '0'
                end
              end

              transform Tms::Transforms::DeleteTmsFields

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if types.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__object_name_types,
                  keycolumn: types.id_field,
                  fieldmap: {types.type_field => types.type_field}
              end

              if langs.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__dd_languages,
                  keycolumn: langs.id_field,
                  fieldmap: {langs.type_field => langs.type_field}
              end

              transform Delete::Fields,
                fields: [types.id_field, langs.id_field]
            end
          end
        end
      end
    end
  end
end
