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
          ActiveSupport::Inflector.transliterate(val).gsub(/[^a-zA-Z0-9]/, '')
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
