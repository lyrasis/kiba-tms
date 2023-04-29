# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      class ContentFields
        class << self
          def call(...)
            new(...).call
          end
        end

        def initialize(jobkey:,
          tablegetter: Tms::Data::CsvEnum)
          @table = tablegetter.call(mod: jobkey)
            .either(
              ->(success) { success },
              ->(failure) {
                warn("Cannot get table for #{jobkey}")
                nil
              }
            )
          @config = Tms.registry
            .resolve(jobkey)
            .creator
            .mod
            .config
        end

        def call
          return unless table

          table.first.headers - omit_fields
        end

        private

        attr_reader :table, :config

        def omit_fields
          base = Tms.tms_fields + config.omitted_fields

          if config.respond_to?(:non_content_fields)
            base + config.non_content_fields
          else
            base
          end
        end
      end
    end
  end
end
