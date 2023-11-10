# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class Classifications
          def initialize
            @xforms = []
            if Tms::Classifications.used?
              @xforms << Tms::Transforms::Objects::ClassificationsMain.new
            end
            if xrefs_used?
              @xforms << Tms::Transforms::Objects::ClassificationsXrefs.new
            end
          end

          def process(row)
            return row if xforms.empty?

            xforms.each { |xform| xform.process(row) }
            row
          end

          private

          attr_reader :xforms

          def xrefs_used?
            Tms::Classifications.used? &&
              Tms::ClassificationXRefs.used? &&
              Tms::ClassificationXRefs.for?("Objects")
          end
        end
      end
    end
  end
end
