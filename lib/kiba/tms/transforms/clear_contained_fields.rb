# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      # Given two fields, A and B:
      #
      # - If A equals B, set value of B to nil
      # - If A contains B, set value of B to nil
      # - If B contains A, set value of A to nil
      class ClearContainedFields

        # @param a [Symbol] the first field to compare
        # @param b [Symbol] the second field to compare
        # @param delim [nil, String] if given, value of each field will be split
        #   using the value given and each separate value in one field compared
        #   to each separate value in the other field. If nil, the whole value
        #   each field is compared against the other as one string
        # @param b_only [Boolean] If false, will set value of `a` to nil if
        #   value of `b` contains value of `a`. If true, the value of `a` is
        #   never set to nil. NOTE: `a` = `b` is always checked first. If true,
        #   value of `b` is set to nil. Then "does `a` contain `b`?" is
        #   checked. If so, `b` is set to nil.
        # @param casesensitive [Boolean] whether to downcase all values for
        #   comparison
        # @param normalized [Boolean] whether to apply Unicode normalization and
        #   strip non alphanumeric characters from values for comparison. Does
        #   not change case on its own.
        def initialize(a:, b:, delim: nil, b_only: false,
                       casesensitive: false,
                       normalized: true)
          @a = a
          @b = b
          @delim = delim
          @b_only = b_only
          @casesensitive = casesensitive
          @normalized = normalized
        end

        def process(row)
          aval = row[a]
          return row if aval.blank?

          bval = row[b]
          return row if bval.blank?

          ap = wrap(aval)
          bp = wrap(bval)

          b_res = bp.reject{ |bv| norm(ap).any?(normalize(bv)) }
            .reject{ |bv| norm(ap).any?{ |av| av[normalize(bv)] } }

          row[a] = finalize(a_result(ap, b_res))
          row[b] = finalize(b_res)
          row
        end

        private

        attr_reader :a, :b, :delim, :b_only, :casesensitive, :normalized

        def a_result(a_arr, b_arr)
          return a_arr if b_only
          return a_arr if b_arr.empty?

          a_arr.reject{ |av| norm(b_arr).any?{ |bv| bv[normalize(av)] } }
        end

        def finalize(arr)
          return nil if arr.empty?

          arr.join(delim)
        end

        def normalize(val)
          lval = casesensitive ? val : val.downcase
          return lval unless normalized

          val = lval.unicode_normalized?(:nfkc) ? lval : lval.unicode_normalize(:nfkc)
          ActiveSupport::Inflector.transliterate(val).gsub(/[^a-zA-Z0-9]/, "")
        end

        def norm(arr)
          arr.map{ |v| normalize(v) }
        end

        def wrap(val)
          delim ? val.split(delim) : [val]
        end
      end
    end
  end
end
