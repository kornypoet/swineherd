module Swineherd
  module Runner
    class BaseRunner

      attr_reader :script
      attr_accessor :config

      def self.register(filename_regexp)
        Swineherd::Runner.registry[filename_regexp] = self
      end

      def initialize(script)
        @script = script
        @config = Swineherd.config.export
      end

    end
  end
end
