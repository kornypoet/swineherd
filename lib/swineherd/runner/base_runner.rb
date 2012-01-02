module Swineherd
  module Runner
    class BaseRunner

      def self.register(filename_regexp)
        Swineherd::Runner.registry[filename_regexp] = self
      end

      attr_reader :script

      def initialize(script)
        @script = script
      end

      def config
        Settings
      end

    end
  end
end
