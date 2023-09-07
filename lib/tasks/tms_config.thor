# frozen_string_literal: true

require "thor"

# Config-related tasks
class TmsConfig < Thor
  desc "derive_initial", "Write initial config to mig directory"
  def derive_initial
    configs = Kiba::Tms::Utils::InitialConfigDeriver.call
    Kiba::Tms::Utils::InitialConfigWriter.call(results: configs)
  end

  desc "derive_diff", "Write diffed config to mig directory"
  def derive_diff
    configs = Kiba::Tms::Utils::InitialConfigDeriver.call
    diffed = Kiba::Tms::Utils::ConfigDiffer.call(configs)
    Kiba::Tms::Utils::InitialConfigWriter.call(
      results: diffed,
      path: File.join(Tms.datadir, "diffed_config.txt")
    )
  end

  desc "single_init", "Print initial config for given module to STDOUT"
  def single_init(mod)
    modconst = Tms.const_get(mod)
    Tms.init_config(modconst)
  end
end
