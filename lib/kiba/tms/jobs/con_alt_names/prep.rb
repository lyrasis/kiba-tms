# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAltNames
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_alt_names,
                destination: :prep__con_alt_names,
                lookup: %i[
                           prep__constituents
                           constituents__by_norm
                          ]
              },
              transformer: prep_xforms
            )
          end

          def prep_xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields

              # Removes rows where alt name value matches linked name in Constituents table
              transform Merge::MultiRowLookup,
                lookup: prep__constituents,
                keycolumn: :constituentid,
                fieldmap: {
                  chkid: :defaultnameid,
                  mainname: Tms::Constituents.preferred_name_field,
                  maintype: :contype}

              transform do |row|
                altid = row[:altnameid]
                chkid = row[:chkid]
                next if altid == chkid

                row
              end
              transform Delete::Fields, fields: :chkid

              # If preferred name field = alphasort, move org names from displayname to alphasort
              if Tms::Constituents.preferred_name_field == :alphasort
                transform do |row|
                  alphasort = row[:alphasort]
                  next row unless alphasort.blank?

                  display = row[:displayname]
                  next row if display.blank?

                  row[:alphasort] = display
                  row[:displayname] = nil

                  row
                end
              end

              transform FilterRows::FieldPopulated, action: :keep, field: Tms::Constituents.preferred_name_field

              # removes rows where preferred form of alt name (normalized) is the same as preferred form
              #   of linked constituent name (normalized)
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: Tms::Constituents.preferred_name_field,
                target: :altnorm
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :mainname,
                target: :mainnorm              
              transform do |row|
                altnorm = row[:altnorm]
                mainnorm = row[:mainnorm]
                next row unless altnorm == mainnorm
              end
              
              transform Merge::MultiRowLookup,
                lookup: constituents__by_norm,
                keycolumn: :altnorm,
                fieldmap: {
                  is_separate_constituent: Tms::Constituents.preferred_name_field,
                  sepcontype: :contype
                }
              transform Delete::Fields, fields: %i[altnorm mainnorm]

              transform Tms::Transforms::ConAltNames::DeriveType

              # force separate constituent type value as altnametype where available
              transform do |row|
                contype = row[:sepcontype]
                next row if contype.blank?

                row[:altnametype] = contype.split(Tms.delim).uniq.join(Tms.delim)
                row
              end
              transform Delete::Fields, fields: %i[sepcontype]
              
              # add :typematch column
              transform do |row|
                main = row[:maintype]
                alt = row[:altnametype]

                if main == alt
                  row[:typematch] = 'y'
                else
                  row[:typematch] = 'n'
                end
                row
              end
            end
          end
        end
      end
    end
  end
end
