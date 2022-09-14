# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Mixin module
      #
      # Modules including this should have the following methods defined:
      #
      # - :target_tables (Array)
      module MultiTableMergeable
        def for?(table)
          target_tables.any?(table)
        end
      end
    end
  end

end
