require 'rubygems'
require 'configliere' ; Configliere.use(:commandline, :env_var, :define)
require 'erubis'
require 'rake'

require 'swineherd/script'
require 'swineherd/runner'
require 'swineherd/filesystem'
require 'swineherd/workflow'

module Swineherd
  # For rake 0.9 compatibility
  include Rake::DSL if defined?(Rake::DSL)
end

Configliere::Param.class_eval do
  def options_for(namespace)
    self.select{|param, val| self.definition_of(param)[namespace.to_sym] }
  end
end
