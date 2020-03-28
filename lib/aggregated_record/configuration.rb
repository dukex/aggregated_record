# typed: true
# frozen_string_literal: true

module AggregatedRecord
  module Configuration
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def created_with(created_with_class)
        self.configuration[:created_with] = created_with_class
      end

      def updated_with(updated_with_class)
        self.configuration[:updated_with] = updated_with_class
      end

      def configuration
        @configuration ||= {}
      end
    end
  end
end
