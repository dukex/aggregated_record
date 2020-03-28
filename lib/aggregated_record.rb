# typed: strict
# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module AggregatedRecord
  class Error < StandardError; end
  # Your code goes here...
end

require "aggregated_record/railtie" if defined?(Rails)
