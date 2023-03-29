# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromConOrgWithInst
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
            :name_compile__from_con_org_with_inst
          end

          def lookups
            base = []
            base << :constituents__by_all_norms if Tms::NameTypeCleanup.done
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              treatment = config.source_treatment[job.send(:jobkey)]
              prefname = Tms::Constituents.preferred_name_field

              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  type = row[:contype]
                  type && type.start_with?('Organization')
                end
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :institution
              transform Append::ToFieldValue,
                field: :constituentid,
                value: '.institution'
              transform Merge::ConstantValue,
                target: :termsource,
                value: 'TMS Constituents.orgs_institution'

              if Tms::NameTypeCleanup.done
                transform FilterRows::WithLambda,
                  action: :reject,
                  lambda: ->(row){ row[prefname] == row[:institution] }
              end

              if treatment == :variant
                transform Merge::ConstantValue,
                  target: :relation_type,
                  value: 'variant term'
                transform Rename::Field, from: :institution, to: :variant_term
                transform Delete::Fields, fields: Tms::NameCompile.variant_nil
              else
                transform Delete::Fields, fields: Tms::NameCompile.org_nil
              end
            end
          end
        end
      end
    end
  end
end
