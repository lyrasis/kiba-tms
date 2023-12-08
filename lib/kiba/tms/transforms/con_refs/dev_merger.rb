# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConRefs
        class DevMerger
          # @param into [Module]
          # @param keycolumn [Symbol]
          # @param lookup [Hash]
          def initialize(into:, keycolumn:, lookup:)
            @into = into
            @keycolumn = keycolumn
            @lookup = lookup
            @xforms = build_xforms
          end

          def process(row)
            xforms.each { |xform| xform.process(row) }
            row
          end

          private

          attr_reader :into, :keycolumn, :xforms, :lookup

          def build_xforms
            %i[org person].map { |source| build_xform(source) }
          end

          def build_xform(source)
            target = "conref_#{source}".to_sym
            Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: keycolumn,
              fieldmap: {
                target => source,
                "#{target}_role".to_sym => :role
              },
              conditions: ->(_orig, rows) do
                rows.reject { |row| row[source].blank? }
              end,
              sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
              delim: Tms.delim,
              null_placeholder: Tms.nullvalue
            )
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
