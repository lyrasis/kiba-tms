# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # Affects only rows with :remarks starting with 'active'.
        #
        # - Changes :datedescription to 'Active Dates'
        # - If :date is blank, moves the :remarks remaining value after 'active ' to the :date
        # - If :date populated, adds warning 'active date in remarks, some other date value in date'
        class ActiveDateFromRemarks
          def initialize
            @eligiblematch = Tms::Constituents.dates.active_remark_match
            @cleanmatch = Tms::Constituents.dates.active_remark_clean_match
            @warntext = "active date in remarks, some other date value in date"
          end

          # @private
          def process(row)
            remarks = row[:remarks]
            return row unless eligible?(remarks)

            row[:datedescription] = "Active Dates"
            date = row[:date]
            date.blank? ? set_active(row, remarks) : row[:warn] = warntext
            row
          end

          private

          attr_reader :eligiblematch, :cleanmatch, :warntext

          def cleaned(remarks)
            remarks.sub(cleanmatch, "")
          end

          def eligible?(remarks)
            return false if remarks.blank?
            return false unless remarks.match?(eligiblematch)

            true
          end

          def set_active(row, remarks)
            row[:remarks] = nil
            row[:date] = cleaned(remarks)
          end
        end
      end
    end
  end
end
