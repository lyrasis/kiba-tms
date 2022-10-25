# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module MapByNorm
          module_function

          def desc
              <<~DESC
                With lookup on normalized version of original name value (i.e. from any table, not controlled by
                constituentid), gives `:person` and `:organization` column from which to merge authorized form
                of name
              DESC
          end

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :names__map_by_norm
              },
              transformer: xforms
            )
          end

          def sources
            if Tms::Names.cleanup_iteration && Tms::Names.cleanup_workflow == :old
              iter = Tms::Names.cleanup_iteration
              "nameclean#{iter}__prep".to_sym
            elsif Tms::Names.cleanup_iteration && !Tms::Names.cleanup_workflow == :old
              warn("#{self.name}: Need to implement new workflow when cleanup iteration")
            else
              :constituents__prep_clean
            end
          end

          def xforms
            if Tms::Names.cleanup_iteration && Tms::Names.cleanup_workflow == :old
              old_cleanup_xforms
            elsif Tms::Names.cleanup_iteration && !Tms::Names.cleanup_workflow == :old
              warn("#{self.name}: Need to implement new workflow when cleanup iteration")
            else
              Kiba.job_segment do
              end
            end
          end

          def old_cleanup_xforms
            Kiba.job_segment do
              prefname = Tms::Constituents.preferred_name_field
              keepfields = %i[constituenttype fp_norm norm] + [prefname]
              transform Delete::FieldsExcept, fields: keepfields
              transform Append::NilFields, fields: %i[person organization]
              transform do |row|
                case row[:constituenttype]
                when 'Person'
                  row[:person] = row[prefname]
                when 'Organization'
                  row[:organization] = row[prefname]
                else
                  row[Tms::Constituents.untyped_default.downcase.to_sym] = row[prefname]
                end
                row
              end
              transform Rename::Field, from: :fp_norm, to: :orig_norm
              transform do |row|
                orignorm = row[:orig_norm]
                if orignorm.blank?
                  row[:orig_norm] = row[:norm]
                end
                row
              end
              transform Delete::Fields, fields: ( %i[constituenttype norm] + [prefname] )
              transform Deduplicate::Table, field: :orig_norm
            end
          end
        end
      end
    end
  end
end
