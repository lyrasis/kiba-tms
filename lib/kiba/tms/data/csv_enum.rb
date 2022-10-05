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
        def initialize(mod:)
          @mod = mod
          if mod.is_a?(Module)
            @job_key = mod.source_job_key
            @path = mod.table_path
          elsif mod.is_a?(Symbol)
            @job_key = mod
            @path = Tms::Table::Obj.new(mod).filename
          else
            fail(TypeError, 'mod must be Module or Symbol')
          end
        end

        # @return [Enumerable]
        def call
          unless File.exist?(path)
            Kiba::Extend::Command::Run.job(job_key)
          end
          csv = CSV.foreach(
            path,
            headers: true,
            header_converters: %i[downcase symbol]
          )
        rescue StandardError => err
          Failure(err)
        else
          Success(csv)
        end

        private

        attr_reader :mod, :path, :job_key
      end
    end
  end
end
