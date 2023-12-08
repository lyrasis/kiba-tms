# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConRefs
        class Merger
          # @param into [Module]
          # @param keycolumn [Symbol]
          def initialize(into:, keycolumn:)
            @into = into
            @keycolumn = keycolumn
            @lookup = Tms.get_lookup(
              jobkey: "con_refs_for__#{lookup_job_name}".to_sym,
              column: :recordid
            )
            @xform = build_xform
          end

          def process(row)
            xform.process(row)
            row
          end

          private

          attr_reader :into, :keycolumn, :xform, :lookup

          def build_xform
            config = into.con_ref_role_to_field_mapping
            if config.empty?
              DevMerger.new(into: into, keycolumn: keycolumn, lookup: lookup)
            else
              RuleMerger.new(
                into: into,
                keycolumn: keycolumn,
                lookup: lookup,
                config: config
              )
            end
          end

          def lookup_job_name
            default = into.filekey
            case default
            when :loans__out
              :loansout
            when :loans__in
              :loansin
            else
              default
            end
          end
        end
      end
    end
  end
end
