# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      # Mix-in module
      module FullerDateSelectable
        def select_fuller_date(a, b)
          da = a.downcase
          db = b.downcase
          return a if da == db

          if da[db]
            da
          elsif db[da]
            db
          else
            nil
          end
        end
      end
    end
  end
end
