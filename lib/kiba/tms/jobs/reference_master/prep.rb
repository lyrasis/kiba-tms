# frozen_string_literal: true

## NOTE: NOT FINISHED YET
module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__reference_master,
                destination: :prep__reference_master,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__ref_formats if Tms::RefFormats.used?
            base << :prep__dd_languages if Tms::DDLanguages.used?
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              if lookups.any?(:prep__ref_formats)
                transform Merge::MultiRowLookup,
                  lookup: prep__ref_formats,
                  keycolumn: :formatid,
                  fieldmap: {format: :format}
              end
              transform Delete::Fields, fields: :formatid

              transform Merge::MultiRowLookup,
                lookup: prep__dd_languages,
                keycolumn: :languageid,
                fieldmap: {language: :language}
              transform Delete::Fields, fields: :languageid

              # populates person and org names from ConXrefs
              if Tms::ConRefs.for?("ReferenceMaster")
                if config.con_ref_name_merge_rules
                  transform Tms::Transforms::ConRefs::Merger,
                    into: config,
                    keycolumn: :referenceid
                end
              end

              if Tms::TextEntries.for?("ReferenceMaster") &&
                  Tms::TextEntriesForReferenceMaster.merger_xforms
                Tms::TextEntriesForReferenceMaster.merger_xforms.each do |xform|
                  transform xform
                end
              end

              unless config.citation_note_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.citation_note_sources,
                  target: :citationnote,
                  delim: config.citation_note_value_separator

              end
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
