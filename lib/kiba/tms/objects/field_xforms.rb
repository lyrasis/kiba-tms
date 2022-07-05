# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Objects
      # Configure transformers to transform data in individual source fields or sets of source fields. If nil,
      #   default processing in prep__objects is used unless field is otherwise omitted from processing
      module FieldXforms
        extend Dry::Configurable
          setting :classifications, default: nil, reader: true
          setting :creditline,
            default: Tms::Transforms::DeriveFieldPair.new(
              source: :creditline,
              newfield: :annotationtype,
              value: 'Credit Line',
              sourcebecomes: :annotationnote
            ),
            reader: true        
          setting :curatorialremarks,
            default: Kiba::Extend::Transforms::Rename::Field.new(
              from: :curatorialremarks,
              to: :curatorialremarks_comment
            ),
            reader: true
          setting :inscribed,
            default: Tms::Transforms::DeriveFieldPair.new(
              source: :inscribed,
              newfield: :inscriptioncontenttype,
              value: 'inscribed',
              sourcebecomes: :inscriptioncontent
            ),
            reader: true
          setting :markings,
            default: Tms::Transforms::DeriveFieldPair.new(
              source: :markings,
              newfield: :inscriptioncontenttype,
              value: '',
              sourcebecomes: :inscriptioncontent
            ),
            reader: true
          setting :medium, default: nil, reader: true
          setting :signed,
            default: Tms::Transforms::DeriveFieldPair.new(
              source: :signed,
              newfield: :inscriptioncontenttype,
              value: 'signature',
              sourcebecomes: :inscriptioncontent
            ),
            reader: true
          # Project-specific transformer class `initialize` method should set lookup using:
          #   `Kiba::Tms::Objects::Config.text_entry_lookup`
          setting :text_entries, default: nil, reader: true
      end
    end
  end
end
