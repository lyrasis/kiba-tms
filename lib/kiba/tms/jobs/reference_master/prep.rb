# frozen_string_literal: true

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
              transformer: [
                initial,
                external_merge,
                config.field_cleaners,
                finalize
              ].compact
            )
          end

          def lookups
            base = []
            base << :prep__ref_formats if Tms::RefFormats.used?
            base << :prep__dd_languages if Tms::DDLanguages.used?
            base
          end

          def initial
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner
            end
          end

          def external_merge
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

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

              if Tms::AltNums.used? && Tms::AltNums.for?("ReferenceMaster")
                key = :alt_nums_reportable_for__reference_master_type_cleanup_merge
                lkup = Tms.get_lookup(
                  jobkey: key,
                  column: :recordid
                )
                transform Merge::MultiRowLookup,
                  lookup: lkup,
                  keycolumn: :referenceid,
                  fieldmap: {
                    num: :altnum,
                    numtype: :number_type
                  },
                  delim: Tms.delim,
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i)

                transform Merge::MultiRowLookup,
                  lookup: lkup,
                  keycolumn: :referenceid,
                  fieldmap: {numnote: :remarks},
                  delim: Tms.delim,
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i)

                transform Prepend::ToFieldValue,
                  field: :numnote,
                  value: "Identifier note: ",
                  multival: true,
                  delim: Tms.delim
              end
            end
          end

          def finalize
            Kiba.job_segment do
              # @todo remove reversal of qualification once better cleanup
              #   is implemented
              transform do |row|
                row[:pubunqual] = nil
                val = row[:publisherorganizationlocal]
                next row if val.blank?

                row[:pubunqual] = if val["(duplicate"]
                  val.sub(/ \(duplicate.*\)/, "")
                else
                  val
                end
                row
              end

              transform Fingerprint::Add,
                fields: %i[placepublished pubunqual],
                target: :orig_pub_fingerprint

              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
