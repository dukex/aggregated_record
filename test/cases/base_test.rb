# typed: false
# frozen_string_literal: true

require "test_helper"


class BaseTest < Test::Unit::TestCase
  def event_store
    @event_store ||= ::RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new, mapper: RubyEventStore::Mappers::NullMapper.new)
  end

  def setup
    AggregateRoot.configure { |config| config.default_event_store = event_store }

    @now = Time.now
    event_store.publish(Post::Created.new(
                          metadata: { timestamp: @now },
                          data: { title: "My Awesome Post", extra_attr_unknown: "An extra attr in event", visibility: :public }
                        ), stream_name: "post/awesome-post")
  end

  def test_finding
    record = Post.find("awesome-post")

    assert_equal record.stream_name, "post/awesome-post"
    assert_equal record.id, "awesome-post"
  end

  def test_creation_event
    record = Post.find("awesome-post")

    assert_equal record.title, "My Awesome Post"
    assert_equal record.created_at, @now
    assert_equal record.updated_at, @now
    assert_equal record.instance_variable_get("@extra_attr_unknown"), "An extra attr in event"
  end

  def test_updation_event
    updated_at = Time.now
    event_store.publish(Post::Updated.new(
                          metadata: { timestamp: updated_at },
                          data: { title: "My First Awesome Post" }
                        ), stream_name: "post/awesome-post")

    record = Post.find("awesome-post")

    assert_equal record.title, "My First Awesome Post"
    assert_equal record.created_at, @now
    assert_equal record.updated_at, updated_at
  end

  def test_publish
    record = Post.find("awesome-post")
    assert record.updated_at
    assert_equal record.visibility, :public

    previous_updated_at = record.updated_at
    event = record.publish(Post::Updated)
    assert_equal event.data[:id], record.id
    assert_not_equal record.updated_at, previous_updated_at
  end

  def test_call_syntax
    record = Post.find("awesome-post")
    previous_updated_at = record.updated_at

    record.(Post::Updated)
    assert_not_equal record.updated_at, previous_updated_at
  end

  def test_publish_with_data_and_parent
    record = Post.find("awesome-post")

    parent_event = record.publish(Post::VisibilityChanged, visibility: :private)
    assert_equal record.visibility, :private

    event = record.publish(Post::VisibilityChanged, { visibility: :public }, parent_event)
    event.metadata
    assert_equal event.metadata[:correlation_id], parent_event.event_id
    assert_equal event.metadata[:causation_id], parent_event.event_id
  end


  def test_reload
    record = Post.find("awesome-post")

    event = record.publish(Post::Updated, title: "Not saved")
    assert event

    record.reload

    assert_equal record.title, "My Awesome Post"
  end

  def test_save
    record = Post.find("awesome-post")

    event = record.publish(Post::Updated, title: "Saved")
    assert event

    record.save

    assert_equal record.title, "Saved"
  end

  def test_create
    record = Post.create!(id: "new-post-1")
    record.reload
    assert_equal record.id, "new-post-1"
  end

  def test_create_with_data
    record = Post.create!(id: "new-post-2", title: "My new post")
    record.reload
    assert_equal record.title, "My new post"
  end

  def test_create_with_parent_event
    parent_event = RubyEventStore::Event.new(event_id: "123456")
    record = Post.create!(id: "new-post-3", parent_event: parent_event)

    event = event_store.read.stream(record.stream_name).forward.first

    assert_equal event.metadata[:correlation_id], parent_event.event_id
    assert_equal event.metadata[:causation_id], parent_event.event_id
  end

  def test_update
    record = Post.create!(id: "new-post-2")

    record.update!(title: "My new post")

    assert_equal record.title, "My new post"
  end

  def test_update_with_parent_event
    parent_event = RubyEventStore::Event.new(event_id: "123456")
    record = Post.create!(id: "new-post-3")
    record.update!(title: 'Test post', parent_event: parent_event)

    event = event_store.read.stream(record.stream_name).forward.last

    assert_instance_of Post::Updated, event

    assert_equal event.metadata[:correlation_id], parent_event.event_id
    assert_equal event.metadata[:causation_id], parent_event.event_id
  end

  def test_link
    record = Post.find("awesome-post")
    comment = Comment.create!(id: "3456789")

    record.link!(comment)

    comments = event_store.read.stream(record.stream_name).of_type([Comment::Created]).to_a
    assert_equal comments.count, 1
    assert_equal comments.first.data[:id], comment.id
  end
end
