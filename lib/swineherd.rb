require 'rubygems'
require 'configliere' ; Configliere.use(:commandline, :env_var, :define,:config_file)
require 'rake'
require 'logger'

#Merge in system and user settings
system_config = "/etc/swineherd.yaml"
user_config   = File.join(ENV['HOME'], '.swineherd.yaml')
Settings.read system_config if File.exists? system_config
Settings.read user_config  if File.exists? user_config

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
