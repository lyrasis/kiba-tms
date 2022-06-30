# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class TextInscriptionXform
          def process(row)
            val = value(row)
            if val.blank?
              row[type_target] = nil
              row[content_target] = nil
            else
              row[type_target] = typeval
              row[content_target] = val
            end
            row.delete(source)
            row
          end

          private

          attr_reader :source, :typeval

          def value(row)
            row[source]
          end

          def type_target
            "#{source}_inscriptioncontenttype".to_sym
          end

          def content_target
            "#{source}_inscriptioncontent".to_sym
          end
        end
      end
    end
  end
end
