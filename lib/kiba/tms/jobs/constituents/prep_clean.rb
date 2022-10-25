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
            ntc_done? && ntc_targets.any?('Constituents')
          end
          extend Tms::Mixins::NameTypeCleanupable

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              prefname = config.preferred_name_field

              if bind.receiver.send(:ntc_needed?)
                transform Rename::Field, from: :norm, to: :prefnormorig
                transform Tms::Transforms::NameTypeCleanup::OverlayAll,
                  lookup: name_type_cleanup__for_constituents,
                  keycolumn: :constituentid,
                  typetarget: :constituenttype,
                  nametarget: prefname
                transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                  source: config.preferred_name_field,
                  target: :norm
                transform Tms::Transforms::Constituents::NormalizeContype
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[contype_norm norm],
                  target: :combined,
                  sep: ' ',
                  delete_sources: false
                transform Deduplicate::FlagAll,
                  on_field: :combined,
                  in_field: :duplicate,
                  explicit_no: false
                transform Delete::Fields, fields: %i[contype_norm]
              else
                transform Copy::Field, from: :norm, to: :prefnormorig
              end
            end
          end
        end
      end
    end
  end
end
