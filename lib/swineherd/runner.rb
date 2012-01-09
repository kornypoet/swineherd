module Swineherd
  module Runner

    @registry = {}
    class << self; attr_accessor :registry; end

    def self.for_script(script)
      klass = @registry.detect{|re,kl| script.filename =~ re}
      raise "No runner found for '#{script.filename}'" unless klass
      klass[1].new(script)
    end

  end
end

require 'swineherd/runner/hadoop_jobconf'
require 'swineherd/runner/pig_jobconf'

require 'swineherd/runner/base_runner'
require 'swineherd/runner/pig_runner'
