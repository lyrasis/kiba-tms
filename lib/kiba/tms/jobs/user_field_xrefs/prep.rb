# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module UserFieldXrefs
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__user_field_xrefs,
                destination: :prep__user_field_xrefs,
                lookup: :prep__user_fields
              },
              transformer: [
                xforms,
                config.prep_xforms
              ].compact
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: config.content_fields

              transform Merge::MultiRowLookup,
                lookup: prep__user_fields,
                keycolumn: :userfieldid,
                fieldmap: {
                  tablename: :tablename,
                  fieldname: :userfieldname
                }
              transform Delete::Fields,
                fields: %i[contextid]
              transform Rename::Field,
                from: :id,
                to: :recordid
            end
          end
        end
      end
    end
  end
end
