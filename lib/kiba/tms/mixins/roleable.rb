# frozen_string_literal: true

require 'csv'

module Kiba
  module Tms
    module Mixins
      # ## Implementation details
      #
      # Modules/classes mixing this in must:
      #
      # extend Tms::Mixins::Tableable
      module Roleable
        def self.extended(mod)
        end

        def merges_roles?
          true
        end
      end
    end
  end
end
