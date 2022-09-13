# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class UniqueFieldValues
        def self.call(...)
          self.new(...).call
        end
        
        def initialize(path, field)
          @path = path
          @field = field
        end

        def call
          vals = {}
          CSV.foreach(path, headers: true, header_converters: %i[downcase symbol]) do |row|
            val = row[field]
            vals[val] = nil unless vals.key?(val)
          end
          vals.keys
        end

        private

        attr_reader :path, :field
      end
    end
  end
end
