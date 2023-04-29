# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module ClassificationReport
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__objects,
                destination: :objects__classification_report,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if Tms::Classifications.used?
              base << :prep__classifications
            end
            if Tms::ClassificationXRefs.used?
              base << :prep__classification_xrefs
            end
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::FieldsExcept,
                fields: %i[objectid objectnumber
                  title objectname]

              transform Merge::MultiRowLookup,
                keycolumn: :objectid,
                lookup: prep__classification_xrefs,
                fieldmap: Tms::Classifications.object_merge_fieldmap,
                delim: Tms.delim
              transform Delete::Fields, fields: :objectid
            end
          end
        end
      end
    end
  end
end
