# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module RefXRefs
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__ref_xrefs,
                destination: :prep__ref_xrefs,
                lookup: :reference_master__xref_lkup
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              transform Tms::Transforms::TmsTableNames
              transform Rename::Field,
                from: :id,
                to: :recordid
              transform Tms.data_cleaner if Tms.data_cleaner

              transform Delete::FieldValueMatchingRegexp,
                fields: :pagenumber,
                match: "^0$"

              transform Merge::MultiRowLookup,
                lookup: reference_master__xref_lkup,
                keycolumn: :referenceid,
                fieldmap: {reference: :heading}

              if config.citation_note_builder
                transform config.citation_note_builder
              end
            end
          end
        end
      end
    end
  end
end
