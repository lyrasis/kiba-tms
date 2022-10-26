# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module PrepMapByNorm
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :names__prep_map_by_norm
              },
              transformer: xforms
            )
          end

          # def sources
          #   if Tms::Names.cleanup_iteration && Tms::Names.cleanup_workflow == :old
          #     iter = Tms::Names.cleanup_iteration
          #     "nameclean#{iter}__prep".to_sym
          #   elsif Tms::Names.cleanup_iteration && !Tms::Names.cleanup_workflow == :old
          #     warn("#{self.name}: Need to implement new workflow when cleanup iteration")
          #   else
          #     :name_compile__unique
          #   end
          # end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  rt = row[:relation_type]
                  norm = row[:prefnormorig]
                  rt && rt == '_main term' && !norm.blank?
                end
              transform Delete::FieldsExcept,
                fields: %i[contype name prefnormorig]
              transform Rename::Field,
                from: :prefnormorig,
                to: :norm
              transform Tms::Transforms::Constituents::NormalizeContype,
                target: :contype
              transform Tms::Transforms::Constituents::AddDefaultContype
            end
          end

          # def old_cleanup_xforms
          #   Kiba.job_segment do
          #     prefname = Tms::Constituents.preferred_name_field
          #     keepfields = %i[constituenttype fp_norm norm] + [prefname]
          #     transform Delete::FieldsExcept, fields: keepfields
          #     transform Append::NilFields, fields: %i[person organization]
          #     transform do |row|
          #       case row[:constituenttype]
          #       when 'Person'
          #         row[:person] = row[prefname]
          #       when 'Organization'
          #         row[:organization] = row[prefname]
          #       else
          #         row[Tms::Constituents.untyped_default.downcase.to_sym] = row[prefname]
          #       end
          #       row
          #     end
          #     transform Rename::Field, from: :fp_norm, to: :orig_norm
          #     transform do |row|
          #       orignorm = row[:orig_norm]
          #       if orignorm.blank?
          #         row[:orig_norm] = row[:norm]
          #       end
          #       row
          #     end
          #     transform Delete::Fields, fields: ( %i[constituenttype norm] + [prefname] )
          #     transform Deduplicate::Table, field: :orig_norm
          #   end
          # end
        end
      end
    end
  end
end
