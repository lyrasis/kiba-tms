# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Citations
        module Main
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__places_finalized,
                destination: :citations__main,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            %i[
              reference_master__prep_clean
              reference_master__journal_lookup
              reference_master__series_lookup
            ].select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              lookups = job.send(:lookups)

              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :drop

              transform Merge::MultiRowLookup,
                lookup: reference_master__prep_clean,
                keycolumn: :referenceid,
                fieldmap: {oldpubplace: :placepublished}

              # Generate full citation
              transform do |row|
                fulltitle = [row[:title], row[:subtitle]].compact
                  .reject(&:empty?)
                  .join(": ")
                sor = if row[:stmtresponsibility].blank?
                  nil
                else
                  row[:stmtresponsibility].delete_suffix(".")
                end
                attributed = [fulltitle, sor].compact
                  .reject(&:empty?)
                  .join(" / ")
                ed = row[:edition].blank? ? nil : row[:edition]
                ser = if row[:series].blank?
                  nil
                else
                  "(#{row[:series]})"
                end
                uptopub = [attributed, ed, ser].compact.join(". ")
                pub = row[:publisherorganizationlocal]
                pubs = if pub.blank?
                  nil
                else
                  pub.split(Tms.delim).join("; ")
                end
                journ = row[:journal].blank? ? nil : "In #{row[:journal]}"
                cite = [row[:volume], row[:numofpages]].compact
                  .reject(&:empty?)
                  .join(", ")
                jcite = if journ.nil?
                  nil
                else
                  [journ, cite, row[:displaydate]].compact
                    .reject(&:empty?)
                    .join(", ")
                end
                pubplc = row[:oldpubplace]
                pubplcs = if pubplc.blank?
                  nil
                else
                  pubplc.split(Tms.delim).join("; ")
                end
                pubandplc = [pubplcs, pubs].compact.join(": ")
                pubstmt = [pubandplc, row[:displaydate]].compact
                  .reject(&:empty?)
                  .join(", ")
                pubinfo = if jcite
                  [uptopub, jcite]
                else
                  [uptopub, pubstmt]
                end
                row[:termfullcitation] = pubinfo.compact.join(". ")
                row
              end

              unless Tms::ReferenceMaster.citation_note_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: Tms::ReferenceMaster.citation_note_sources,
                  target: :citationnote,
                  delim: Tms::ReferenceMaster.citation_note_value_separator
              end

              transform Delete::Fields,
                fields: %i[referenceid drop oldpubplace displaydate
                  orig_pub_fingerprint]

              if lookups.include?(:reference_master__journal_lookup)
                transform Merge::MultiRowLookup,
                  lookup: reference_master__journal_lookup,
                  keycolumn: :journal,
                  fieldmap: {
                    j_termsourcecitationlocal: :heading
                  }
                transform Delete::Fields, fields: :journal
              else
                transform Rename::Field,
                  from: :journal,
                  to: :j_termsourcecitationlocal
              end
              if lookups.include?(:reference_master__series_lookup)
                transform Merge::MultiRowLookup,
                  lookup: reference_master__series_lookup,
                  keycolumn: :series,
                  fieldmap: {
                    s_termsourcecitationlocal: :heading
                  }
                transform Delete::Fields, fields: :series
              else
                transform Rename::Field,
                  from: :series,
                  to: :s_termsourcecitationlocal
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[j_termsourcecitationlocal
                  s_termsourcecitationlocal],
                target: :termsourcecitationlocal,
                delim: Tms.delim

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[agentpersonlocalrole agentorganizationlocalrole],
                target: :role,
                delim: Tms.delim

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[callnumber num],
                target: :resourceident,
                delim: Tms.delim

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[numbertype numtype],
                target: :type,
                delim: Tms.delim

              transform Rename::Fields, fieldmap: {
                heading: :termdisplayname,
                title: :termtitle,
                subtitle: :termsubtitle,
                format: :termtype,
                volume: :termvolume,
                language: :termlanguage
              }

              # These fields are loaded with pubdate details
              transform Delete::Fields,
                fields: %i[edition numofpages publisherorganizationlocal
                  pubplace]

              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
