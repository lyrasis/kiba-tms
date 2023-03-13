require 'thor'

# Config-related tasks
class Config < Thor
  desc 'derive_initial', 'Write initial config to mig directory'
  def derive_initial
    Kiba::Tms::Utils::InitialConfigDeriver.call
  end
end
