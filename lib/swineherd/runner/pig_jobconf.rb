module Swineherd
  module PigJobconf

      Settings.define :pig_home, :description => "Path to pig install; ENV['PIG_HOME'] by default.", :env_var => 'PIG_HOME'
      Settings.define :run_mode, :description => "Set execution mode -x: (local|mapreduce)",:default => "mapreduce"

      #   Settings.namespace :pig do
      Settings.define :params, :description => "Pig -p PARAM=val script parameters, accessible as $PARAM in the script.",:pig => true,:default => {}
      #   Setting.namespace :jobconf do
      Settings.define :combine_splits, :description => "pig.splitCombination", :pig => true, :pig_jobconf => true
      #   end
      #   end

      def pig_jobconf_options
        #config.pig.jobconf?
        config.options_for(:pig_jobconf).inject([]){ |options,option| options << jobconf_for(option[0]) }.compact
      end

      def param_options_string
        #config.pig.param?
        config.options_for(:pig)[:params].map do |param,val|
          "-param %s=%s" % [param.to_s.upcase, val]
        end
      end
  end
end
