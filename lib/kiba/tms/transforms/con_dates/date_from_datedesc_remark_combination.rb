# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # If :date is blank and :datedescription equals given type and :remarks begins with given string(s),
        #   move value of :remarks to :date
        class DateFromDatedescRemarkCombination
          def initialize
            @config = Tms::Constituents.dates.datedescription_variants
          end

          # @private
          def process(row)
            return row unless eligible?(row)

            row[:date] = cleaned_remark(row)
            row[:remarks] = nil
            row
          end

          private

          attr_reader :config

          def cleaned_remark(row)
            row[:remarks].sub(
              Regexp.new("^#{to_delete(row)} +",
                Regexp::IGNORECASE), ""
            )
          end

          def eligible?(row)
            date = row[:date]
            return false unless date.blank?

            remark = row[:remarks]
            return false if remark.blank?

            type = row[:datedescription]
            return false unless config.keys.any?(type)

            lower = remark.downcase
            config[type].any? { |val| lower.start_with?(val) }
          end

          def to_delete(row)
            remark = row[:remarks].downcase
            config[row[:datedescription]]
              .select { |val| remark.start_with?(val) }
              .first
          end
        end
      end
    end
  end
end
