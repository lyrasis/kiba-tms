# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::ConAddress::RemoveRedundantAddressLines do
  subject(:xform) { described_class.new(lookup: lookup) }
  let(:lookup) do
    {
      1 => [{constituentid: 1, prefname: "b, a", nonprefname: "a b"}],
      4 => [{constituentid: 4, prefname: "g, h", nonprefname: "h g"}],
      5 => [{constituentid: 5, prefname: "i, j", nonprefname: "j i"}],
      6 => [{constituentid: 6, prefname: "k, l", nonprefname: "l k"}]
    }
  end
  let(:result) { input.map { |row| xform.process(row) } }
  let(:input) do
    [
      {constituentid: 1, displayname1: "ab"},
      {constituentid: 4, displayname1: "hg", displayname2: "g, h"},
      {constituentid: 5, displayname1: "j i", displayname2: "ij"},
      {constituentid: 6, displayname1: "bar", displayname2: "bats!"}
    ]
  end

  let(:expected) do
    [
      {constituentid: 1, displayname1: "ab"},
      {constituentid: 4, displayname1: "hg", displayname2: nil},
      {constituentid: 5, displayname1: nil, displayname2: "ij"},
      {constituentid: 6, displayname1: "bar", displayname2: "bats!"}
    ].map { |h| h.merge({person: nil, org: nil}) }
  end

  it "transforms as expected" do
    expect(result).to eq(expected)
  end
end
