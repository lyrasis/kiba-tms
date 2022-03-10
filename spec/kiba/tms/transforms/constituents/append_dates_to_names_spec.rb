# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Tms::Transforms::Constituents::AppendDatesToNames do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }
  let(:transforms) do
    Kiba.job_segment do
      transform Kiba::Tms::Transforms::Constituents::AppendDatesToNames
    end
  end
  let(:input) do
    [
      {constituenttype: 'Individual', displayname: 'Ann B.', alphasort: 'B., Ann', begindateiso: '1901', enddateiso: '1929'},
      {constituenttype: 'Individual', displayname: 'Ann C.', alphasort: 'C., Ann', begindateiso: '1902', enddateiso: ''},
      {constituenttype: 'Individual', displayname: 'Ann D.', alphasort: 'D., Ann', begindateiso: '', enddateiso: '1930'},
      {constituenttype: 'Individual', displayname: 'Ann E.', alphasort: 'E., Ann', begindateiso: '', enddateiso: ''},
      {constituenttype: 'Institution', displayname: 'Foo', alphasort: 'Foo', begindateiso: '1901', enddateiso: '1929'},
      {constituenttype: 'Institution', displayname: 'Bar', alphasort: 'Bar', begindateiso: '1902', enddateiso: ''},
      {constituenttype: 'Institution', displayname: 'Baz', alphasort: 'Baz', begindateiso: '', enddateiso: '1930'},
      {constituenttype: 'Institution', displayname: 'Bam', alphasort: 'Bam', begindateiso: '', enddateiso: ''},
      {constituenttype: 'Individual', displayname: '', alphasort: 'B., Ann', begindateiso: '1901', enddateiso: '1929'},
      {constituenttype: 'Individual', displayname: nil, alphasort: 'B., Ann', begindateiso: '1901', enddateiso: '1929'}
    ]
  end

  context 'when append to types = none' do
    before{ Kiba::Tms.config.constituents.date_append.to_types = [:none] }

    it 'passes rows through unaltered' do
      expect(result).to eq(input)
    end
  end
  
  context 'when append to types = all' do
    before{ Kiba::Tms.config.constituents.date_append.to_types = [:all] }

    let(:expected) do
      [
        'Ann B., (1901 - 1929)',
        'Ann C., (1902 -)',
        'Ann D., (- 1930)',
        'Ann E.',
        'Foo, (1901 - 1929)',
        'Bar, (1902 -)',
        'Baz, (- 1930)',
        'Bam',
        '',
        nil
      ]
    end
    
    it 'transforms as expected' do
      expect(result.map{ |row| row[:displayname]}).to eq(expected)
    end
  end

  context 'when append to types = Individual' do
    before{ Kiba::Tms.config.constituents.date_append.to_types = ['Individual'] }

    let(:expected) do
      [
        'Ann B., (1901 - 1929)',
        'Ann C., (1902 -)',
        'Ann D., (- 1930)',
        'Ann E.',
        'Foo',
        'Bar',
        'Baz',
        'Bam',
        '',
        nil
      ]
    end
    
    it 'transforms as expected' do
      expect(result.map{ |row| row[:displayname]}).to eq(expected)
    end
  end
end
