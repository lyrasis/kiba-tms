# frozen_string_literal: true

require "fileutils"

module Helpers
  module_function

  def enable_test_interfaces_on_configs
    Tms.enable_test_interface
    Tms.configs
      .each do |cfg|
        next unless cfg.respond_to?(:enable_test_interface)

        cfg.enable_test_interface
      end
  end

  def auto_derive_config
    init_config = Tms::Utils::InitialConfigDeriver.call(mode: :quiet)
    Tms::Utils::InitialConfigWriter.call(results: init_config)
    set_auto_derived_initial_config
  end

  # rubocop:disable Security/Eval
  def set_auto_derived_initial_config
    eval(File.read(File.join(Tms.datadir, "initial_config.txt")))
  end
  # rubocop:enable Security/Eval

  def setup_project
    # OVERRIDE KIBA::EXTEND'S DEFAULT OPTIONS
    Kiba::Extend.config.csvopts = {encoding: "utf-8",
                                   headers: true,
                                   header_converters: [:symbol, :downcase],
                                   converters: %i[stripplus nulltonil]}
    Kiba::Extend.config.delim = "|"

    Kiba::Extend.config.pre_job_task_action = :nuke
    taskdirs = %w[working reports].map do |dir|
      File.join(Kiba::Tms.datadir, dir)
    end
    Kiba::Extend.config.pre_job_task_directories = taskdirs
    Kiba::Extend.config.pre_job_task_mode = :no
    registry = Kiba::Extend::Registry::FileRegistry.new
    Kiba::Extend.config.registry = registry
    Kiba::Tms.config.registry = Kiba::Extend.registry

    set_auto_derived_initial_config
    # Setup kiba-tms options
    Kiba::Tms::ObjGeography.config.empty_fields = {
      concession: [nil, "", "0", ".0000"],
      easting: [nil, "", "0", ".0000"],
      elevation: [nil, "", "0", ".0000"],
      excavation: [nil, "", "0", ".0000"],
      latitude: [nil, "", "0", ".0000"],
      longitude: [nil, "", "0", ".0000"],
      lot: [nil, "", "0", ".0000"],
      mapreferencenumber: [nil, "", "0", ".0000"],
      northing: [nil, "", "0", ".0000"],
      regionalcorp: [nil, "", "0", ".0000"],
      subcontinent: [nil, "", "0", ".0000"],
      utm: [nil, "", "0", ".0000"],
      villagecorporation: [nil, "", "0", ".0000"]
    }
    Kiba::Tms::ObjGeography.config.controlled_types = :all
    Kiba::Tms::Places.config.hierarchy_fields =
      %i[city state country nation continent]
    Kiba::Tms::Places.config.misc_note_patterns =
      [/ *\((?:\?--|)see GR\) *$/,
        / *\((?:former|panorama|per artist|from literary reference)\)$/i,
        / *\((?:from book.*|formerly|see remarks|stereoview)\)$/i,
        / *\((?:see notes)\)$/i,
        / *\((?:current|earlier|former|previous) name\)$/i,
        /(?:; former name|see remarks)/i]
    Kiba::Tms.meta_config

    # DEPENDENT CONFIG goes here

    Kiba::Tms.finalize_config
    Kiba::Tms::RegistryData.register
    Kiba::Tms.registry.transform
    Kiba::Tms.registry.freeze
  end

  def reset_configs
    Tms.reset_config
    Tms.configs
      .each do |cfg|
        next unless cfg.respond_to?(:reset_config)

        cfg.reset_config
      end
  end

  def copy_from_test(file, target = nil, dir = "working")
    to = target || file.sub(/_[A-Z]\d+\.csv/, ".csv")
    FileUtils.cp(
      File.join(Tms.datadir, "test", file),
      File.join(Tms.datadir, dir, to)
    )
  end

  def clear_working
    dirpath = File.join(Tms.datadir, "working")
    FileUtils.rm_rf(dirpath)
    FileUtils.mkdir(dirpath)
    dirpath = File.join(Tms.datadir, "prepped")
    FileUtils.rm_rf(dirpath)
    FileUtils.mkdir(dirpath)
  end

  def run(job)
    entry = Tms.registry.resolve(job)
    result = entry.creator.call
    {job: result, path: entry.path}
  end

  def result_path(job)
    jobres = run(job)
    jobres[:path]
  end
end
