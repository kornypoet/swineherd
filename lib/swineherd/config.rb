Configliere::Param.class_eval do
  def options_for(namespace)
    self.select{ |param, val| self.definition_of(param)[namespace.to_sym] }
  end
end

module Swineherd
  # For rake 0.9 compatibility
  include Rake::DSL if defined?(Rake::DSL)

  def self.system_config() '/etc/swineherd.yaml' ; end
  
  def self.user_config()   return unless ENV["HOME"] ; File.join(ENV['HOME'], '.swineherd.yaml') ; end

  def self.config
    return @config if @config
    config = Configliere::Param.new
    config.read system_config if File.exists? system_config
    config.read user_config   if File.exists? user_config
    @config ||= config
  end
end

Swineherd.config.define :template_dir, :default => '/tmp',     :description => 'Where interpolated Swineherd::Script templates are written to'
Swineherd.config.define :output_root,  :default => '/mnt/tmp', :description => 'Root directory where Swineherd::Workflow output is written to.' 
Swineherd.config.define :verbose ,     :default => true,       :description => 'Option for verbose logging during Swineherd::Workflow execution.'
