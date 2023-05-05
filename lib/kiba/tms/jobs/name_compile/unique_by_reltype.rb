# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module UniqueByReltype
          module_function

          def job(reltype:, value:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: "name_compile__unique_split_#{reltype}".to_sym
              },
              transformer: [
                xforms(value),
                send(get_xform(reltype), reltype)
              ]
            )
          end

          def get_xform(reltype)
            if reltype == :main || reltype == :variant
              :auth_aware_xforms
            else
              :non_auth_aware_xforms
            end
          end

          def xforms(value)
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :relation_type,
                value: value
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :name,
                value: Tms::NameTypeCleanup.dropped_name_indicator
            end
          end

          def auth_aware_xforms(reltype)
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              naval = config.na_in_migration_value
              p_editable = config.send("#{reltype}_person_editable".to_sym)
              p_not_editable = config.send(
                "#{reltype}_person_not_editable".to_sym
              )
              o_editable = config.send("#{reltype}_org_editable".to_sym)
              o_not_editable = config.send(
                "#{reltype}_org_not_editable".to_sym
              )
              transform Fingerprint::Add,
                fields: p_editable,
                delim: "␟",
                target: :fp_p_ed
              transform Fingerprint::Add,
                fields: o_editable,
                delim: "␟",
                target: :fp_o_ed
              transform Fingerprint::Add,
                fields: p_not_editable + config.not_editable_internal,
                delim: "␟",
                target: :fp_p_ned
              transform Fingerprint::Add,
                fields: o_not_editable + config.not_editable_internal,
                delim: "␟",
                target: :fp_o_ned

              transform do |row|
                contype = row[:contype]
                if contype.start_with?("P")
                  p_not_editable.each { |fld| row[fld] = naval }
                  row[:fp_o_ed] = nil
                  row[:fp_o_ned] = nil
                else
                  o_not_editable.each { |fld| row[fld] = naval }
                  row[:fp_p_ed] = nil
                  row[:fp_p_ned] = nil
                end
                row
              end
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[fp_p_ed fp_o_ed],
                target: :fp_editable,
                delim: "",
                delete_sources: true
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[fp_p_ned fp_o_ned],
                target: :fp_not_editable,
                delim: "",
                delete_sources: true
            end
          end

          def non_auth_aware_xforms(reltype)
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              naval = config.na_in_migration_value
              editable = config.send("#{reltype}_editable".to_sym)
              not_editable = config.send("#{reltype}_not_editable".to_sym)

              transform Fingerprint::Add,
                fields: editable,
                delim: "␟",
                target: :fp_editable
              transform Fingerprint::Add,
                fields: not_editable + config.not_editable_internal,
                delim: "␟",
                target: :fp_not_editable

              transform do |row|
                not_editable.each { |fld| row[fld] = naval }
                row
              end
            end
          end
        end
      end
    end
  end
end
