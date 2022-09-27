# frozen_string_literal: true

require 'pp'

module Kiba
  module Tms
    module Utils
      class TableMergeStatusCreator
        def self.call
          self.new.call
        end

        def initialize
          @setting = 'Kiba::Tms.config.table_merge_status ='
          @val = {}
          @exist = Tms.table_merge_status
        end

        def call
          target_tables.each do |target|
            val[target] = source_tables(target)
          end
          puts to_s
        end

        private

        attr_reader :setting, :val, :exist

        def source_tables(target)
          Tms.for_merge_into(target)
            .map{ |src| [
              src.to_s.delete_prefix('Kiba::Tms::'),
              :todo
            ] }
            .to_h
        end

        def target_tables
          Tms.configs.select{ |config| config.respond_to?(:target_tables) }
            .map{ |config| config.target_tables }
            .flatten
            .sort
            .uniq
        end

        def to_s
          [setting, pp(val.merge(exist))].join("\n")
        end
      end
    end
  end
end
