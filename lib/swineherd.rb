require 'rubygems'
require 'configliere' ; Configliere.use(:commandline, :env_var, :define,:config_file)
require 'rake'
require 'logger'
require 'erubis'

#Merge in system and user settings
SYSTEM_CONFIG_PATH = "/etc/swineherd.yaml"
USER_CONFIG_PATH   = File.join(ENV['HOME'], '.swineherd.yaml')
Settings.read SYSTEM_CONFIG_PATH if File.exists? SYSTEM_CONFIG_PATH
Settings.read USER_CONFIG_PATH  if File.exists? USER_CONFIG_PATH

Settings.define :template_root, :default => "/tmp/",:description => "Where interpolated Swineherd::Script templates are written to"

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
