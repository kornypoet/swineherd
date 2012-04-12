require 'configliere' ; Configliere.use(:commandline, :env_var, :define,:config_file)
require 'rake'
require 'logger'
require 'erubis'
require 'swineherd-fs'


#Merge in system and user settings
SYSTEM_CONFIG_PATH = "/etc/swineherd.yaml" unless defined?(SYSTEM_CONFIG_PATH)
USER_CONFIG_PATH   = File.join(ENV['HOME'], '.swineherd.yaml') unless defined?(USER_CONFIG_PATH)

Configliere::Param.class_eval do
  def options_for(namespace)
    self.select{|param, val| self.definition_of(param)[namespace.to_sym] }
  end
end

module Swineherd
  # For rake 0.9 compatibility
  include Rake::DSL if defined?(Rake::DSL)

  def self.config
    return @config if @config
    config = Configliere::Param.new
    config.read SYSTEM_CONFIG_PATH if File.exists? SYSTEM_CONFIG_PATH
    config.read USER_CONFIG_PATH  if File.exists? USER_CONFIG_PATH
    @config ||= config
  end
end

Swineherd.config.define :template_root, :default => "/tmp/",:description => "Where interpolated Swineherd::Script templates are written to"

require 'swineherd/script'
require 'swineherd/runner'
require 'swineherd/workflow'
