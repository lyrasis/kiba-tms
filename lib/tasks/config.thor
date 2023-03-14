require 'thor'

# Config-related tasks
class Config < Thor
  desc 'derive_initial', 'Write initial config to mig directory'
  def derive_initial
    Kiba::Tms::Utils::InitialConfigDeriver.call
  end

  desc 'single_init', 'Print initial config for given module to STDOUT'
  def single_init(mod)
    modconst = Tms.const_get(mod)
    Tms.init_config(modconst)
  end
end
