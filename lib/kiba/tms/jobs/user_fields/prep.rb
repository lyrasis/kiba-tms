# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module UserFields
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__user_fields,
                destination: :prep__user_fields,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            %i[
              user_fields__used
              tms__dd_contexts
            ]
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

              transform Merge::MultiRowLookup,
                lookup: user_fields__used,
                keycolumn: :userfieldid,
                fieldmap: {used: :userfieldid}
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :used

              transform Merge::MultiRowLookup,
                lookup: tms__dd_contexts,
                keycolumn: :contextid,
                fieldmap: {context: :description}

              context_map = Tms.context_to_table_mapping
              transform do |row|
                row[:tablename] = nil
                context = row[:context]
                next row if context.blank?

                row[:tablename] = if context_map.key?(context)
                  context_map[context]
                else
                  "Provide Tms.context_to_table_mapping for #{context}"
                end
                row
              end

              transform Delete::Fields,
                fields: %i[used contextid context]
            end
          end
        end
      end
    end
  end
end
