# frozen_string_literal: true

module Kiba
  module Tms
    module ExhVenObjXrefs
      extend Dry::Configurable

      module_function

      # ## ABOUT THIS TABLE
      #
      # Contains specific relationship data that is not modeled in a structured
      #   way (or, really, at all) in CS. If this table contains data a client
      #   needs to migrate, the structured data in the table needs to be
      #   collapsed down into a free-text note value. Then, that note needs to
      #   be merged into either Object record (with a label indicating which
      #   exhibition and venue the note describes) or Exhibition record (with a
      #   label indicating which object and venue the note describes)
      #
      # For mmm, no new Exhibition/Object relationships could be derived from
      #   this table (in addition to those already derived from ExhObjXrefs.

      extend Tms::Mixins::Tableable
    end
  end
end
