# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class DeletePrefixesFromDisplaydate
          def initialize
            @field = :displaydate
            @cleaners = Tms::Constituents.displaydate_deletable_prefixes.map do |prefix|
              Clean::RegexpFindReplaceFieldVals.new(
                fields: :displaydate,
                find: "^#{prefix},? *",
                replace: "",
                casesensitive: false
              )
            end
          end

          def process(row)
            cleaners.each { |cleaner| cleaner.process(row) }
            row
          end

          private

          attr_reader :field, :cleaners
        end
      end
    end
  end
end
