# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Kiba
  module Tms
    module Services
      class EmptyFieldsDeriver
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        def self.call(...)
          self.new(...).call
        end

        # @param table [Kiba::Tms::Table::Obj]
        # @param mod [Module]
        def initialize(mod:,
                       checker: Tms::Services::EmptyFieldChecker,
                       settingobj: Tms::Data::ConfigSetting,
                       failobj: Tms::Data::DeriverFailure
                      )
          @mod = mod
          @checker = checker
          @settingobj = settingobj
          @failobj = failobj
          @setting = :empty_fields
        end

        def call
          to_chk = yield gather_to_check
          checked = yield checked_results(to_chk)
          result = yield result_hash(checked)

          Success(settingobj.new(mod: mod,
                                 name: setting,
                                 value: result)
                 )
        end

        private

        attr_reader :mod, :checker, :settingobj, :failobj, :setting

        def checked_results(to_chk)
          result = to_chk.map do |field, criteria|
              checker.call(mod: mod, field: field, criteria: criteria)
            end.compact
        rescue StandardError => err
          Failure(
            failobj.new(mod: mod, name: setting, err: err)
          )
        else
          Success(result)
        end

        def gather_to_check
          result = mod.empty_candidates
            .map{ |field| [field, [nil, "", "0", ".0000"]] }
            .to_h
            .merge(mod.empty_fields)
        rescue StandardError => err
          Failure(
            failobj.new(mod: mod, name: setting, err: err)
          )
        else
          Success(result)
        end

        def result_hash(checked)
          result = {}
          checked.each do |spec|
            result[spec[:field]] = spec[:criteria]
          end
        rescue StandardError => err
          Failure(
            failobj.new(mod: mod, name: setting, err: err)
          )
        else
          Success(result)
        end
      end
    end
  end
end
