# typed: strict
# frozen_string_literal: true

require "aggregate_root"

module AggregatedRecord
  class Railtie < Rails::Railtie
    config.after_initialize do
      ::AggregateRoot.configure do |config|
        config.default_event_store ||= ::Rails.configuration.event_store
      end
    end
  end
end
