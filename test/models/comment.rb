# typed: true
# frozen_string_literal: true

class Comment < AggregatedRecord::Base
  Created = Class.new(RubyEventStore::Event)
  Updated = Class.new(RubyEventStore::Event)

  created_with Comment::Created
  updated_with Comment::Updated

  ## ATTRIBUTES
  attr_reader :body
end
