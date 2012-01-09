module Swineherd
  module PigJobconf

      Swineherd.config.define :pig_home, :description => "Path to pig install; ENV['PIG_HOME'] by default.", :env_var => 'PIG_HOME'
      Swineherd.config.define :run_mode, :description => "Set execution mode -x: (local|mapreduce)",:default => "mapreduce"

      #   Swineherd.config.namespace :pig do
      Swineherd.config.define :params, :description => "Pig -p PARAM=val script parameters, accessible as $PARAM in the script.",:pig => true,:default => {}
      #   Setting.namespace :jobconf do
      Swineherd.config.define :combine_splits, :description => "pig.splitCombination", :pig => true, :pig_jobconf => true
      #   end
      #   end

      def pig_jobconf_options
        #Swineherd.config.pig.jobconf?
        config.options_for(:pig_jobconf).inject([]){ |options,option| options << jobconf_for(option[0]) }.compact
      end

      def param_options_string
        #Swineherd.config.pig.param?
        config.options_for(:pig)[:params].map do |param,val|
          "-param %s=%s" % [param.to_s.upcase, val]
        end
      end
  end
end
