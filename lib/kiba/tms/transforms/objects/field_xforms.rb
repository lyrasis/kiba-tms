# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class FieldXforms
          def initialize
            @rowct = 0
            @config = Tms::Objects
            @xforms = []
          end

          def process(row)
            set_xforms(row) if rowct == 0
            xforms.each { |xform| xform.process(row) }
            row
          end

          private

          attr_reader :rowct, :config, :xforms

          def set_xforms(row)
            row.keys.each { |field| set_xform(field) }
            @xforms.flatten!
            @rowct = 1
          end

          def set_xform(field)
            return unless config.field_xform_for?(field)

            @xforms << config.send("#{field}_xform".to_sym)
          end
        end
      end
    end
  end
end
