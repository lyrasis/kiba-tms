# frozen_string_literal: true

require "thor"

class TmsInfo < Thor
  desc "list_mixins", "Lists TMS config/table module mixins"
  def list_mixins
    puts ""
    puts mixins
  end

  desc "tables_used", "List tables included in migration"
  def tables_used
    puts ""
    puts Tms.configs
      .select { |config| config.respond_to?(:used?) && config.used? }
      .map(&:name)
      .sort
  end

  desc "tables_unused", "List tables not included in migration"
  def tables_unused
    puts ""
    puts Tms.configs
      .select { |config| config.respond_to?(:used?) && !config.used? }
      .map(&:name)
      .sort
  end

  desc "what_mixes_in MIXIN",
    "Lists tables that mix in the given module"
  def what_mixes_in(mixin)
    unless mixins.include?(mixin)
      puts "\nMixin value must be one of:\n#{mixins.join("\n")}"
      exit 1
    end

    puts ""
    puts Tms.configs
      .select { |cfg| cfg.is_a?(Tms::Mixins.const_get(mixin)) }
      .map(&:name)
      .sort
  end

  no_commands do
    def mixins
      Tms::Mixins.constants.map(&:to_s).sort
    end
  end
end
