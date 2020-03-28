# typed: strong
# frozen_string_literal: true

require "bundler/setup"
require "aggregated_record"

require "test/unit"
require "byebug"

require "ruby_event_store"
require_relative "models/post"
require_relative "models/comment"
