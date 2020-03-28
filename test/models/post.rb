# typed: true
# frozen_string_literal: true

class Post < AggregatedRecord::Base
  Created = Class.new(RubyEventStore::Event)
  Updated = Class.new(RubyEventStore::Event)
  VisibilityChanged = Class.new(RubyEventStore::Event)

  created_with Post::Created
  updated_with Post::Updated

  ## ATTRIBUTES
  attr_reader :title, :visibility

  ## HANDLERS
  def apply_visibility_changed(event)
    @visibility = event.data[:visibility]
  end
end
