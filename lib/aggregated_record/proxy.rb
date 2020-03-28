# typed: true
# frozen_string_literal: true

module AggregatedRecord
  class Proxy
    attr_reader :base_class, :stream_name

    def initialize(stream_name, base_class)
      @stream_name = stream_name
      @base_class = base_class
    end

    extend Forwardable
    def_delegators :all, :each, :map, :select, :first, :last

    def all
      store.read
        .stream(stream_name)
        .forward
        .of_type([creation_class])
        .to_a
        .map { |event| event.data[:id] }
        .map(&method(:find))
    end

    def find(id)
      base_class.find(id)
    end

    private

      def store
        AggregateRoot.configuration.default_event_store
      end

      def creation_class
        base_class.configuration[:created_with]
      end
  end
end
