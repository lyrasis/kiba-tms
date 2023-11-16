# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjContext
        class MergeXforms
          def initialize
            @config = Tms::ObjContext
            field_check = config.content_fields
              .map { |field| [field, xform_for?(field)] }
              .group_by { |arr| arr[1] }
            @mergeable = field_check[true].map(&:first)
            field_check[nil]&.map(&:first)&.each do |field|
              warn("WARNING: Define a merger for ObjContext.#{field}")
            end
            @xforms = build_xforms
          end

          def process(row)
            xforms.each { |xform| xform.process(row) }
            row
          end

          private

          attr_reader :config, :mergeable, :xforms

          def build_xforms
            @xforms = []
            mergeable.each { |field| set_xforms(field) }
            @xforms.flatten!
          end

          def set_xforms(field)
            @xforms << config.send("#{field}_mergers".to_sym)
              .map { |klass, args| args ? klass.new(**args) : klass.new }
          end

          def xform_for?(field)
            methname = "#{field}_mergers".to_sym
            true if config.respond_to?(methname) &&
              config.send(methname).is_a?(Hash)
          end
        end
      end
    end
  end
end
