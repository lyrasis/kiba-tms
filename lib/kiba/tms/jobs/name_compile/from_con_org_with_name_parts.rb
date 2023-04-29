# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromConOrgWithNameParts
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__for_compile,
                destination: jobkey,
                lookup: lookups
              },
              transformer: xforms,
              helper: config.multi_source_normalizer
            )
          end

          def jobkey
            :name_compile__from_con_org_with_name_parts
          end

          def ntc_needed?
            return false unless ntc_done?

            ntc_targets.any?(termsource) && treatment == :contact_person
          end
          extend Tms::Mixins::NameTypeCleanupable

          def lookups
            base = []
            if ntc_needed?
              base << :name_type_cleanup__for_con_org_with_name_parts
            end
            if Tms::NameTypeCleanup.done && treatment == :contact_person
              base << :constituents__by_all_norms
            end
            base.select { |job| Tms.job_output?(job) }
          end

          def termsource
            "Constituents.orgs_name_detail"
          end

          def treatment
            config.source_treatment[jobkey]
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              treatment = job.send(:treatment)
              prefname = Tms::Constituents.preferred_name_field

              transform Tms::Transforms::NameCompile::SelectConOrgsWithNameParts

              transform Append::ToFieldValue,
                field: :constituentid,
                value: ".namedetail"
              transform Merge::ConstantValue,
                target: :termsource,
                value: job.send(:termsource)

              if treatment == :variant
                transform Tms::Transforms::NameCompile::DeriveVariantName,
                  mode: :main,
                  from: :nameparts
              elsif treatment == :contact_person
                transform Tms::Transforms::NameCompile::DeriveAndSetContactFromOrg,
                  mode: :main,
                  person_name_from: :nameparts
              end

              if job.send(:ntc_needed?)
                transform Tms::Transforms::NameTypeCleanup::ExplodeMultiNames,
                  lookup: name_type_cleanup__for_con_org_with_name_parts
                if treatment == :variant
                  # no cleanup needed
                elsif treatment == :contact_person
                  transform Tms::Transforms::NameTypeCleanup::OverlayAll,
                    typetarget: {"_main term" => :contype},
                    nametarget: {
                      "_main term" => prefname,
                      "contact_person" => :related_term
                    }
                end
                transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                  source: prefname,
                  target: :derivednorm
                transform Merge::MultiRowLookup,
                  lookup: constituents__by_all_norms,
                  keycolumn: :derivednorm,
                  fieldmap: {cleaned: prefname},
                  conditions: ->(row, rows) do
                    return [] unless row[:contype] &&
                      row[:contype].start_with?("Person")
                    rows.select { |r| r[:contype] && r[:contype] == "Person" }
                  end
                transform do |row|
                  next row if row[:cleaned].blank?

                  row[prefname] = row[:cleaned]
                  row
                end
                transform Delete::Fields, fields: %i[derivednorm cleaned]
              end
            end
          end
        end
      end
    end
  end
end
