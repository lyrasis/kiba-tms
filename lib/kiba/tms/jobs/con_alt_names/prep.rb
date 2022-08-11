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
                  conname: Tms::Constituents.preferred_name_field,
                  conauthtype: :contype}

              transform do |row|
                altid = row[:altnameid]
                chkid = row[:chkid]
                next if altid == chkid

                row
              end
              transform Delete::Fields, fields: :chkid

              if Tms::Constituents.altnames.qualify_anonymous
                transform Tms::Transforms::ConAltNames::QualifyAnonymous
              end
              
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
                source: :conname,
                target: :connorm              
              transform do |row|
                altnorm = row[:altnorm]
                connorm = row[:connorm]
                next row unless altnorm == connorm
              end
              
              transform Merge::MultiRowLookup,
                lookup: constituents__by_norm,
                keycolumn: :altnorm,
                fieldmap: {
                  altconname: Tms::Constituents.preferred_name_field,
                  sepconauthtype: :conauthtype,
                  altnameconid: :constituentid
                }
              transform Delete::Fields, fields: %i[altnorm connorm]

              transform Tms::Transforms::ConAltNames::DeriveType

              # force separate constituent type value as altauthtype where available
              transform do |row|
                conauthtype = row[:sepconauthtype]
                next row if conauthtype.blank?

                row[:altauthtype] = conauthtype.split(Tms.delim).uniq.join(Tms.delim)
                row
              end
              transform Delete::Fields, fields: %i[sepconauthtype]
              
              # add :typematch column
              transform do |row|
                con = row[:conauthtype]
                alt = row[:altauthtype]

                if con == alt
                  row[:typematch] = 'y'
                else
                  row[:typematch] = 'n'
                end
                row
              end

              transform Rename::Fields, fieldmap: {
                Tms::Constituents.preferred_name_field => :altname,
                constituentid: :mainconid,
                nametype: :altnametype
              }

              transform Tms::Transforms::ConAltNames::DeleteRedundantInstitutionValues
            end
          end
        end
      end
    end
  end
end
