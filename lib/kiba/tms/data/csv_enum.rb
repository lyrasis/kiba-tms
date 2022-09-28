# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module Kiba
  module Tms
    module Data
      class CsvEnum
        include Dry::Monads[:result]

        class << self
          def call(...)
            self.new(...).call
          end
        end

        # @param mod [Module]
        def initialize(mod)
          @mod = mod
          @path = mod.table_path
        end

        # @return [Enumerable]
        def call
          csv = CSV.foreach(
            mod.table_path,
            headers: true,
            header_converters: %i[downcase symbol]
          )
        rescue StandardError => err
          Failure(err)
        else
          Success(csv)
        end

        private

        attr_reader :mod

      end
    end
  end
end