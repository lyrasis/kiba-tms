# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhVenuesXrefs
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__exh_venues_xrefs,
                destination: :prep__exh_venues_xrefs,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:names__by_constituentid]
            if Tms::IndemnityResponsibilities.used
              base << :prep__indemnity_responsibilities
            end
            if Tms::InsuranceResponsibilities.used
              base << :prep__insurance_responsibilities
            end
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields,
                  fields: config.omitted_fields
              end
              transform Tms.data_cleaner if Tms.data_cleaner

              if Tms::ConRefs.for?('ExhVenuesXrefs')
                if config.con_ref_name_merge_rules
                  transform Tms::Transforms::ConRefs::Merger,
                    into: config,
                    keycolumn: :exhvenuexrefid
                end
              end

              %i[person org].each do |type|
                transform Merge::MultiRowLookup,
                  lookup: names__by_constituentid,
                  keycolumn: :constituentid,
                  fieldmap: {type=>type}
                transform Delete::FieldValueIfEqualsOtherField,
                  delete: type,
                  if_equal_to: "venue#{type}".to_sym
              end
              transform Delete::Fields, fields: :constituentid
              transform Delete::EmptyFields

              indfields = %i[indemnityfromlender indemnityfrompreviousvenue
                             indemnityatvenue indemnityreturn]
              if lookups.any?(:prep__indemnity_responsibilities)
                indfields.each do |field|
                  next if config.omitted_fields.any?(field)

                  transform Merge::MultiRowLookup,
                    lookup: prep__indemnity_responsibilities,
                    keycolumn: field,
                    fieldmap: {field => :responsibility}
                end
              else
                transform Delete::Fields, fields: indfields
              end

              insfields = %i[insurancefromlender insurancefrompreviousvenue
                             insuranceatvenue insurancereturn]
              if lookups.any?(:prep__insurance_responsibilities)
                insfields.each do |field|
                  next if config.omitted_fields.any?(field)

                  transform Merge::MultiRowLookup,
                    lookup: prep__insurance_responsibilities,
                    keycolumn: field,
                    fieldmap: {field => :responsibility}
                end
              else
                transform Delete::Fields, fields: insfields
              end
              transform Tms::Transforms::InsuranceIndemnityNote
              transform do |row|
                row[:prefix] = nil
                insind = row[:insind]
                next row if insind.blank?

                row[:prefix] = row[:venueorg]
                row
              end
              warn('WARNING: Transformation to create prefix for :insind has '\
                   'only been verified for mmm')

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[prefix insind],
                target: :insindnote,
                sep: ':%CR%',
                delete_sources: true
            end
          end
        end
      end
    end
  end
end
