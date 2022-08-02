# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAltNames
        module CategorizedPostCleanup
          module_function

          def job
            return unless Tms::Names.cleanup_iteration
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_alt_names,
                destination: :con_alt_names__categorized_post_cleanup,
                lookup: %i[
                           nameclean__by_constituentid
                           persons__by_norm
                           orgs__by_norm
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: nameclean__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: { person: :person, org: :org }

                transform Merge::MultiRowLookup,
                  lookup: persons__by_norm,
                  keycolumn: :person,
                  fieldmap: { pan_retained: :alt_names }

                transform Merge::MultiRowLookup,
                  lookup: orgs__by_norm,
                  keycolumn: :org,
                  fieldmap: { oan_retained: :alt_names }

                transform CombineValues::FromFieldsWithDelimiter, sources: %i[pan_retained oan_retained], target: :retained,
                  sep: '|', delete_sources: true

                # if alt name recorded in row is not in retained alt names, delete row
                transform do |row|
                  retained_val = row.fetch(:retained, '')
                  if retained_val.blank?
                    row[:kept] = 'n - no altnames for constituent in cleaned up data'
                    next row
                  end

                  retained = retained_val.split('|')
                  alt = row[Tms::Constituents.preferred_name_field]
                  if alt.blank?
                    row[:kept] = 'n - no usable altname value in ConAltNames'
                    next row
                  end
                  

                  unless retained.any?(alt)
                    row[:kept] = 'n - altnames in cleaned up data do not include this one'
                    next row
                  end

                  row[:kept] = 'y'
                  row
                end

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :nametitle,
                find: '\.',
                replace: ''
            end
          end
        end
      end
    end
  end
end

