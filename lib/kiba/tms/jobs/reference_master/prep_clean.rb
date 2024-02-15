# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module PrepClean
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__reference_master,
                destination: :reference_master__prep_clean,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.headings_needed && config.headings_returned
              base << :reference_master__headings_returned
            end
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              if config.placepublished_done
                origlkup = Tms.get_lookup(
                  jobkey: :reference_master__pubplace_cleaned_lkup,
                  column: :orig_fingerprint
                )
                transform Merge::MultiRowLookup,
                  lookup: origlkup,
                  keycolumn: :orig_pub_fingerprint,
                  fieldmap: {
                    orig_placepublished: :placepublished
                  }
                transform Merge::MultiRowLookup,
                  lookup: origlkup,
                  keycolumn: :orig_pub_fingerprint,
                  fieldmap: {
                    orig_publisher: :publisher
                  }

                mergelkup = Tms.get_lookup(
                  jobkey: :reference_master__pubplace_cleaned_lkup,
                  column: :merge_fingerprint
                )
                transform Merge::MultiRowLookup,
                  lookup: mergelkup,
                  keycolumn: :orig_pub_fingerprint,
                  fieldmap: {
                    merge_placepublished: :placepublished
                  }
                transform Merge::MultiRowLookup,
                  lookup: mergelkup,
                  keycolumn: :orig_pub_fingerprint,
                  fieldmap: {
                    merge_publisher: :publisher
                  }

                # keep best placepublished
                transform do |row|
                  fields = %i[merge_placepublished orig_placepublished]
                  val = fields.map { |field| row[field] }
                    .compact
                    .reject(&:empty?)
                    .first
                  if val
                    cleanval = val.split(Tms.delim)
                      .map(&:strip)
                      .join(Tms.delim)
                  else
                    val
                  end
                  fields.each { |field| row.delete(field) }
                  row.delete(:placepublished)
                  row[:placepublished] = cleanval
                  row
                end

                # best publisher from cleanup
                transform do |row|
                  fields = %i[merge_publisher orig_publisher]
                  val = fields.map { |field| row[field] }
                    .compact
                    .reject(&:empty?)
                    .first
                  fields.each { |field| row.delete(field) }
                  nonull = if val
                    val.split(Tms.delim)
                      .map(&:strip)
                      .reject { |val| val == "%NULLVALUE%" }
                      .join(Tms.delim)
                  else
                    val
                  end
                  row[:best_publisherorganizationlocal] = nonull
                  row
                end

                transform Cspace::NormalizeForID,
                  source: :pubunqual,
                  target: :normunqual
                transform Cspace::NormalizeForID,
                  source: :best_publisherorganizationlocal,
                  target: :norm,
                  delim: Tms.delim

                # reconcile publishers
                transform do |row|
                  newpub = row[:best_publisherorganizationlocal]
                  conpub = row[:publisherorganizationlocal]
                  row[:chk] = nil

                  if newpub.blank? && conpub.blank?
                    next row
                  elsif !newpub.blank? && conpub.blank?
                    next row
                  elsif newpub.blank? && !conpub.blank?
                    row[:best_publisherorganizationlocal] = conpub
                  elsif !newpub.blank? && !conpub.blank?
                    newpubs = newpub.split(Tms.delim).map(&:strip)
                    next row if newpubs.include?(conpub.strip)

                    normunqual = row[:normunqual]
                    norm = row[:norm]
                    if normunqual == norm
                      row[:best_publisherorganizationlocal] = conpub
                    elsif normunqual == norm.delete(Tms.delim)
                      row[:best_publisherorganizationlocal] = conpub
                    elsif norm.split(Tms.delim).include?(normunqual)
                      norms = norm.split(Tms.delim)
                      inspt = norms.find_index(normunqual)
                      to_replace = newpubs[inspt]
                      newpubs.insert(inspt, conpub)
                      newpubs.delete(to_replace)
                      row[:best_publisherorganizationlocal] = newpubs.join(
                        Tms.delim
                      )
                    end
                  end
                  row
                end

                transform Delete::Fields,
                  fields: %i[pubunqual orig_pub_fingerprint normunqual
                    norm chk publisherorganizationlocal]
                transform Rename::Field,
                  from: :best_publisherorganizationlocal,
                  to: :publisherorganizationlocal
              end

              if lookups.any?(:reference_master__headings_returned)
                transform Merge::MultiRowLookup,
                  lookup: reference_master__headings_returned,
                  keycolumn: :referenceid,
                  fieldmap: {
                    heading: :heading,
                    drop: :drop
                  }
              end
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
