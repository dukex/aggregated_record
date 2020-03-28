# typed: false
# frozen_string_literal: true

require "test_helper"


class RelationTest < Test::Unit::TestCase
  def event_store
    @event_store ||= ::RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new, mapper: RubyEventStore::Mappers::NullMapper.new)
  end

  def setup
    AggregateRoot.configure { |config| config.default_event_store = event_store }

    @post = Post.find("43221")

    event_store.publish(Post::Created.new(
                          data: { title: "My Awesome Post", extra_attr_unknown: "An extra attr in event", visibility: :public }
                        ), stream_name: @post.stream_name)


    event_store.within do
      c1 = Comment.find("1234")
      c1.publish Comment::Created, body: "Really awesome Post"
      c1.save

      c2 = Comment.find("2431")
      c2.publish Comment::Created, body: "Meh"
      c2.save
    end.subscribe(->(event) {
                    event_store.link(event.event_id, stream_name: @post.stream_name)
                  }, to: Comment::Created).call

    @post.reload
  end

  def test_all
    comments = Comment.in(@post.stream_name).all
    assert_equal comments.count, 2
    assert_equal comments.first.body, "Really awesome Post"
    assert_equal comments.last.body, "Meh"
  end

  def test_map
    Comment.in(@post.stream_name).map do |comment|
      assert comment
    end
  end

  def test_select
    comments = Comment.in(@post.stream_name).select do |comment|
      comment.id == "2431"
    end

    assert_equal comments.count, 1
    assert_equal comments.first.body, "Meh"
  end
end
