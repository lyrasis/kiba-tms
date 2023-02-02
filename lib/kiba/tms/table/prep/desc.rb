# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Prep
        # Return job description for prepped table
        class Desc
          def self.call(table_key)
            self.new(table_key).call
          end

          def initialize(table_key)
            @table_key = table_key
          end

          def call
            if private_methods.any?(table_key)
              send(table_key)
            else
              ''
            end
          end

          private

          attr_reader :table_key

          def obj_locations
            "Deletes omitted fields\nDeletes empty-equivalent field values "\
              "from :loclevel, :dateout, :tempticklerdate, :approver, "\
              ":handler, :requestedby\nRuns client-specific initial data "\
              "cleaner if configured\nADDS ROW FINGERPRINT for collapsing "\
              "rows with identical data into one LMI procedure\nMerges in "\
              "human readable values in :objectnumber, :location_purpose "\
              ":transport_status, :transport_type\nConverts numeric :tempflag "\
              "field value to y/n in :is_temp?"
          end
        end
      end
    end
  end
end
