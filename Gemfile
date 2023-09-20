# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem "kiba-extend", git: "https://github.com/lyrasis/kiba-extend.git",
  branch: "main"
gem "emendate",
  git: "https://github.com/kspurgin/emendate.git",
  branch: "main"

group :documentation do
  gem "kramdown" # markdown parser for generating documentation
  gem "yard"
end

group :test do
  gem "rspec-custom",
  git: "https://github.com/kspurgin/rspec-custom.git",
  branch: "main"
end

gemspec
