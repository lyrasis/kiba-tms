# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module PrepClean
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__constituents,
                destination: :constituents__prep_clean,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if ntc_needed?
              base << :name_type_cleanup__for_constituents
            end
            base
          end

          def ntc_needed?
            ntc_done? && ntc_targets.any?("Constituents")
          end
          extend Tms::Mixins::NameTypeCleanupable

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              prefname = config.preferred_name_field

              if bind.receiver.send(:ntc_needed?)
                transform Rename::Fields, fieldmap: {
                  norm: :prefnormorig,
                  nonprefnorm: :nonprefnormorig
                }

                transform Tms::Transforms::NameTypeCleanup::MergeCorrectData,
                  lookup: name_type_cleanup__for_constituents
                transform Tms::Transforms::NameTypeCleanup::ExplodeMultiNames

                transform Tms::Transforms::NameTypeCleanup::OverlayAll,
                  typetarget: :constituenttype
                transform Copy::Field,
                  from: :constituenttype,
                  to: :contype
                transform Tms::Transforms::Names::NormalizeContype
                transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                  source: prefname,
                  target: :norm
                transform Tms::Transforms::NameCompile::DisambiguateConstituentDuplicates
                transform Tms::Transforms::Constituents::CleanRedundantOrgNameDetails
                transform do |row|
                  id = row[:constituentid]
                  row[:exploded] = id["_exploded"] ? "exp" : nil
                  row
                end
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[contype_norm norm exploded],
                  target: :combined,
                  delim: " ",
                  delete_sources: false
                transform Deduplicate::FlagAll,
                  on_field: :combined,
                  in_field: :duplicate,
                  explicit_no: false
                transform Delete::Fields, fields: %i[contype_norm exploded]
                transform FilterRows::FieldPopulated,
                  action: :keep,
                  field: prefname
                transform Sort::ByFieldValue, field: :constituentid
                transform do |row|
                  cid = row[:constituentid]
                  row[:normid] = if cid["exploded"]
                    cid.sub(/_exploded.*$/, "")
                  else
                    cid
                  end
                  row
                end

              else
                transform Copy::Field, from: :norm, to: :prefnormorig
                transform Copy::Field, from: :nonprefnorm, to: :nonprefnormorig
                transform Copy::Field,
                  from: :constituentid,
                  to: :normid
                transform Tms::Transforms::NameCompile::DisambiguateConstituentDuplicates
              end
            end
          end
        end
      end
    end
  end
end
