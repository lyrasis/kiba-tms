# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAltNames
        module PrepClean
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_alt_names,
                destination: :con_alt_names__prep_clean,
                lookup: lookups
              },
              transformer: prep_xforms
            )
          end

          def lookups
            base = %i[
                      constituents__prep_clean
                      constituents__by_norm
                     ]
            if ntc_needed?
              base << :name_type_cleanup__for_con_alt_names
            end
            base
          end

          def ntc_needed?
            ntc_done? && ntc_targets.any?('ConAltNames')
          end
          extend Tms::Mixins::NameTypeCleanupable

          def prep_xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              prefname = Tms::Constituents.preferred_name_field

              if bind.receiver.send(:ntc_needed?)
                transform Tms::Transforms::NameTypeCleanup::ExplodeMultiNames,
                  lookup: name_type_cleanup__for_con_alt_names,
                  keycolumn: :altnameid
                transform Tms::Transforms::NameTypeCleanup::OverlayAll,
                  typetarget: :altauthtype
                transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                  source: :altname,
                  target: :altnorm

                # Remove altname rows where, cleaned altnorm = cleaned main name
                #   norm
                transform Merge::MultiRowLookup,
                  lookup: constituents__prep_clean,
                  keycolumn: :mainconid,
                  fieldmap: {
                    conname: prefname,
                    conauthtype: :contype,
                    mainnorm: :norm
                  }
                transform do |row|
                  next if row[:mainnorm] == row[:altnorm]

                  row
                end

               transform Merge::MultiRowLookup,
                lookup: constituents__by_norm,
                keycolumn: :altnorm,
                fieldmap: {
                  altconname: prefname,
                  altconauthtype: :contype,
                  altnameconid: :constituentid
                }
              transform Delete::Fields, fields: %i[connorm]

              transform Tms::Transforms::Constituents::DeriveType, mode: :alt
              transform Tms::Transforms::Constituents::NormalizeContype,
                source: :altauthtype,
                target: :alttype

              # force separate constituent type value as altauthtype where
              #   available
              transform do |row|
                alttype = row[:altconauthtype]
                next row if alttype.blank?

                row[:altauthtype] = alttype.split(Tms.delim).uniq.join(Tms.delim)
                row
              end

              # add :typematch column
              transform do |row|
                con = row[:conauthtype]
                alt = row[:alttype]

                if con == alt
                  row[:typematch] = 'y'
                else
                  row[:typematch] = 'n'
                end
                row
              end
              transform Tms::Transforms::ConAltNames::DeleteRedundantInstitutionValues
              end

            end
          end
        end
      end
    end
  end
end
