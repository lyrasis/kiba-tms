# frozen_string_literal: true

require 'kiba/tms'

# Namespace for the overall project
module Project
  module_function

  Kiba::Tms.base_config

  # OVERRIDE KIBA::EXTEND'S DEFAULT OPTIONS
  Kiba::Extend.config.csvopts = {encoding: 'utf-8',
                                 headers: true,
                                 header_converters: [:symbol, :downcase],
                                 converters: %i[stripplus nulltonil]}
  Kiba::Extend.config.delim = '|'

  Kiba::Extend.config.pre_job_task_action = :nuke
#  Kiba::Extend.config.pre_job_task_backup_dir = File.join(datadir, 'backup')
#  taskdirs = %w[working reports prepped].map do |dir|
  taskdirs = %w[working reports].map do |dir|
    File.join(Kiba::Tms.datadir, dir)
  end
  Kiba::Extend.config.pre_job_task_directories = taskdirs
  Kiba::Extend.config.pre_job_task_mode = :no

  # Setup kiba-tms options
  Kiba::Tms::ObjGeography.config.empty_fields = {
    :concession => [nil, "", "0", ".0000"],
    :easting => [nil, "", "0", ".0000"],
    :elevation => [nil, "", "0", ".0000"],
    :excavation => [nil, "", "0", ".0000"],
    :latitude => [nil, "", "0", ".0000"],
    :longitude => [nil, "", "0", ".0000"],
    :lot => [nil, "", "0", ".0000"],
    :mapreferencenumber => [nil, "", "0", ".0000"],
    :northing => [nil, "", "0", ".0000"],
    :regionalcorp => [nil, "", "0", ".0000"],
    :subcontinent => [nil, "", "0", ".0000"],
    :utm => [nil, "", "0", ".0000"],
    :villagecorporation => [nil, "", "0", ".0000"]
  }
  Kiba::Tms::ObjGeography.config.controlled_types = :all
  Kiba::Tms::Places.config.hierarchy_fields =
    %i[city state country nation continent]
  Kiba::Tms::Places.config.worksheets = [
    "places_worksheet_1.csv"
  ]
  Kiba::Tms::Places.config.returned = [
    "places_worksheet_1.csv"
  ]
  Kiba::Tms::Places.config.misc_note_patterns =
    [/ *\((?:\?--|)see GR\) *$/,
     / *\((?:former|panorama|per artist|from literary reference)\)$/i,
     / *\((?:from book.*|formerly|see remarks|stereoview)\)$/i,
     / *\((?:see notes)\)$/i,
     / *\((?:current|earlier|former|previous) name\)$/i,
     /(?:; former name|see remarks)/i
    ]
  Kiba::Tms.meta_config

  # DEPENDENT CONFIG goes here

  Kiba::Tms.finalize_config
  Kiba::Tms::RegistryData.register
  Kiba::Tms.registry.transform
  Kiba::Tms.registry.freeze
end
