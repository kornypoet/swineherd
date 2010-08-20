require 'rubygems'
require 'configliere' ; Configliere.use(:commandline, :env_var, :define)
module Swineherd
  autoload :Hfile,     'swineherd/hdfs'
  autoload :PigTask,   'swineherd/pig_task'
  autoload :PigScript, 'swineherd/pig_script'
end