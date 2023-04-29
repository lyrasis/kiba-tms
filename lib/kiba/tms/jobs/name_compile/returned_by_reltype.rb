# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module ReturnedByReltype
          module_function

          def job(reltype:, value:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__returned_compile,
                destination: "name_compile__returned_split_#{reltype}".to_sym
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
            end
          end

          def auth_aware_xforms(reltype)
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              p_not_editable = config.send(
                "#{reltype}_person_not_editable".to_sym
              )
              o_not_editable = config.send(
                "#{reltype}_org_not_editable".to_sym
              )
              p_decode = Fingerprint::Decode.new(
                fingerprint: :fp_not_editable,
                source_fields: p_not_editable + config.not_editable_internal,
                delim: "␟",
                prefix: "fp",
                delete_fp: true
              )
              o_decode = Fingerprint::Decode.new(
                fingerprint: :fp_not_editable,
                source_fields: o_not_editable + config.not_editable_internal,
                delim: "␟",
                prefix: "fp",
                delete_fp: true
              )

              transform do |row|
                row[:discarded_edit] = nil
                contype = row[:contype]
                source = row[:termsource]
                reverted = {}

                if source == "clientcleanup"
                  row.delete(:fp_not_editable)
                  fields = if contype.start_with?("P")
                    p_not_editable
                  else
                    o_not_editable
                  end

                  fields.each do |field|
                    val = row[field]
                    next if val.blank?

                    reverted[field] = val
                    row[field] = nil
                  end
                else
                  if contype.start_with?("P")
                    fields = p_not_editable + config.not_editable_internal
                    p_decode.process(row)
                  else
                    fields = o_not_editable + config.not_editable_internal
                    o_decode.process(row)
                  end

                  fields.each do |field|
                    orig = "fp_#{field}".to_sym
                    nowval = row[field]
                    origval = row[orig]
                    row.delete(orig)
                    next if nowval.blank? && origval.blank?
                    next if nowval == origval

                    reverted[field] = nowval
                    row[field] = origval
                  end
                end
                next row if reverted.empty?

                row[:discarded_edit] = reverted.to_s
                row
              end
            end
          end

          def non_auth_aware_xforms(reltype)
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              not_editable = config.send("#{reltype}_not_editable".to_sym)
              decode = Fingerprint::Decode.new(
                fingerprint: :fp_not_editable,
                source_fields: not_editable + config.not_editable_internal,
                delim: "␟",
                prefix: "fp",
                delete_fp: true
              )

              transform do |row|
                row[:discarded_edit] = nil
                source = row[:termsource]
                reverted = {}

                if source == "clientcleanup"
                  row.delete(:fp_not_editable)
                  fields = not_editable

                  fields.each do |field|
                    val = row[field]
                    next if val.blank?

                    reverted[field] = val
                    row[field] = nil
                  end
                else
                  fields = not_editable + config.not_editable_internal
                  decode.process(row)

                  fields.each do |field|
                    orig = "fp_#{field}".to_sym
                    nowval = row[field]
                    origval = row[orig]
                    row.delete(orig)
                    next if nowval.blank? && origval.blank?
                    next if nowval == origval

                    reverted[field] = nowval
                    row[field] = origval
                  end
                end
                next row if reverted.empty?

                row[:discarded_edit] = reverted.to_s
                row
              end
            end
          end
        end
      end
    end
  end
end
