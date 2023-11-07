# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDisplayBios
        class Cleaner
          def process(row)
            vals = [row[:displaybio], row[:remarks]].reject(&:blank?)
            row[:bio] = vals.join(Tms.notedelim)
            row
          end
        end
      end
    end
  end
end
