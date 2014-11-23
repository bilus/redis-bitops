class Redis
  module Bitops

    # Configurable settings.
    #
    class Configuration

      # Number of bytes per one sparse bitmap chunk.
      #
      attr_accessor :default_bytes_per_chunk

      # Granulatity of MULTI transactions. Currently supported values are :bitmap and nil.
      #
      attr_accessor :transaction_level

      def initialize
        reset!
      end

      def reset!
        @default_bytes_per_chunk = 32 * 1024
        @transaction_level = :bitmap
      end
    end

    extend self
    attr_accessor :configuration

    # Call this method to modify defaults in your initializers.
    #
    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end
  end

  Bitops.configure {}
end
