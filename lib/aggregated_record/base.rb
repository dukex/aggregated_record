# typed: true
# frozen_string_literal: true

require "aggregate_root"
require "active_support/inflector/methods"
require "active_model"

module AggregatedRecord
  # @abstract
  class Base
    include ::AggregateRoot
    include Configuration

    include ::ActiveModel::Conversion
    include ::ActiveModel::Validations

    attr_reader :stream_name,
                :created_at,
                :updated_at,
                :id

    class << self
      # Create a new instance of the record and load it from repository
      #
      # @example Find a new post
      #   post = Post.find("321")
      #   post.stream_name # 'post/321'
      # @note the stream by default is generated using the class name and the id
      # @param id the record id
      # @return [AggregatedRecord::Base] the record load
      def find(*ids)
        id = define_id(ids)
        object = new(id, define_stream_name(id))
        repository.load(object, object.stream_name)
      end

      def create!(data)
        id = define_id(data.delete(:id))
        parent_event = data.delete(:parent_event)

        new(id, define_stream_name(id)).tap do |record|
          record.create!(data, parent_event)
        end.reload
      end

      # Filter record in a given stream
      #
      # @example Find comments to a given post
      #   post = Post.find('312')
      #   comment = Comment.in(post.stream_name).first
      #   comment.body # lorem ipsum
      #
      # @param [String] the stream name
      # @return [AggregatedRecord::Relation]
      def in(stream_name)
        AggregatedRecord::Proxy.new(stream_name, self)
      end

      # @!visibility private
      def repository
        ::AggregateRoot::Repository.new
      end

      private

        def define_id(ids)
          [ids].flatten.join("/")
        end

        def define_stream_name(id)
          [stream_name_prefix, id].join("/")
        end

        def stream_name_prefix
          ActiveSupport::Inflector.underscore(self.to_s)
        end
    end

    def initialize(id, stream_name)
      @id = id
      @stream_name = stream_name
    end

    # Save the unpublshed events
    #
    # @example
    #   record = Post.find("awesome-post")
    #   record.publish(Post::Updated, title: "Saved")
    #   record.save
    #   record.title # "Saved"
    def save
      self.class.repository.store(self, stream_name)
    end

    # Publish a new event to the record stream
    #
    # @example Publish an event
    #   record = Post.find("awesome-post")
    #   record.publish(Post::Updated)
    # @example Publish an event with data
    #   parent_event = record.publish(Post::VisibilityChanged, visibility: :private)
    # @example Publish an event with parent event
    #   record.publish(Post::VisibilityChanged, { visibility: :public }, parent_event)
    # @example Using call syntax
    #   record.(Post::VisibilityChanged, visibility: :private)
    # @param event_class [RubyEventStore::Event]
    # @param data [Hash]
    # @param previous_event [RubyEventStore::Event]
    # @return [RubyEventStore::Event]
    def publish(event_class, data = {}, previous_event = nil)
      event = event_class.new(data: { id: id }.merge(data))
      event.correlate_with(previous_event) unless previous_event.nil?
      apply event
      event
    end

    alias :call :publish

    # Reload the record
    #
    # @example
    #   record = Post.find("awesome-post")
    #   record.update!(title: "Not saved")
    #   record.reload
    #   record.title # "My Awesome Post"
    # @return [Base]
    def reload
      self.class.repository.load(self, stream_name)
    end

    # Create a record
    #
    # @example
    #   post = Post.find('awesome-post')
    #   post.create!(title: 'My Awesome Post', body: 'lorem ipsum', visibility: :private)
    # @return [RubyEventStore::Event]
    def create!(data = {}, previous_event = nil)
      publish(self.class.configuration[:created_with], data, previous_event).tap do
        save
      end
    end

    # Update a record
    #
    # @example
    #   post = Post.find('awesome-post')
    #   post.create!(title: 'My x Awesome Post', body: 'lorem ipsum', visibility: :private)
    #   post.title # 'My x Awesome Post'
    #   post.update!(title: 'My Awesome Post')
    #   post.title # 'My Awesome Post'
    # @return [RubyEventStore::Event]
    def update!(data)
      previous_event = data.delete(:parent_event)

      publish(self.class.configuration[:updated_with], data, previous_event).tap do
        save
      end
    end

    # Link an event to the record stream
    #
    # @example
    #   post = Post.find('awesome-post')
    #   comment = Comment.find('21345674321')
    #   event = comment.create!(body: 'Nice post bro')
    #   post.link!(event.stream_name)
    # @return [RubyEventStore::Event]
    def link!(record)
      event = event_store.read.stream(record.stream_name).forward.first

      event_store.link(
        event.event_id,
        stream_name: stream_name
      )
    end

    def persisted?
      @persisted == true
    end

    private

      def apply_created(event)
        return unless event.kind_of?(self.class.configuration[:created_with])
        @created_at = event.metadata[:timestamp]
        @persisted = true
        update_with_event(event)
      end

      def apply_updated(event)
        return unless event.kind_of?(self.class.configuration[:updated_with])
        update_with_event(event)
      end

      def update_with_event(event)
        @updated_at = event.timestamp
        event.data.each do |(key, value)|
          instance_variable_set("@#{key}", value)
        end
      end

      def event_store
        AggregateRoot.configuration.default_event_store
      end
  end
end
