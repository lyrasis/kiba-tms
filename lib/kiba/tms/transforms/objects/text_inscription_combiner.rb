# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class TextInscriptionCombiner
          def initialize
            @sources = Tms.objects.text_inscription_source_fields
            @targets = Tms.objects.text_inscription_target_fields
          end

          def process(row)
            targets.each do |target|
              row[target] = combined(row, target)
              temp_fields(target).each{ |field| row.delete(field) }
            end
            row
          end

          private

          attr_reader :sources, :targets

          def combined(row, target)
            values(row, target).join(Tms.delim)
          end

          def temp_fields(target)
            sources.map{ |source| "#{source}_#{target}".to_sym } 
          end

          def values(row, target)
            temp_fields(target).map{ |field| row[field] }.reject{ |val| val.blank? }
          end
        end
      end
    end
  end
end
