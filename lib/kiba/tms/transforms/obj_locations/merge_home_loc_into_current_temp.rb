# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class MergeHomeLocIntoCurrentTemp
          def initialize(homelocprefix: 'normallocation')
            @targets = %w[locationlocal locationoffsite
                          organizationlocal].map{ |target|
              ["#{homelocprefix}#{target}".to_sym, nil]
            }.to_h
            @merger = Tms::Transforms::ObjLocations::LocToColumns.new(
              locsrc: :homelocationname,
              authsrc: :homelocationauth,
              target: homelocprefix
            )
          end

          def process(row)
            if current_temp?(row)
              merger.process(row)
            else
              %i[homelocationname homelocationauth].each{ |f| row.delete(f) }
              row.merge(targets)
            end
          end

          private

          attr_reader :targets, :merger

          def current?(row)
            row[:current] && row[:current] == 'y'
          end

          def current_temp?(row)
            current?(row) && temp?(row)
          end

          def temp?(row)
            row[:is_temp] && row[:is_temp] == 'y'
          end
        end
      end
    end
  end
end
