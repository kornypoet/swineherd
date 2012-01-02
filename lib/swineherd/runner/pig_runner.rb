module Swineherd
  module Runner
    class PigRunner < BaseRunner
      include HadoopJobconf
      include PigJobconf

      register /.*\.pig\.?.*/

      def pig_runner_path
        [config.pig_home,"bin","pig"].join("/")
      end

      def run_mode
        "-x #{config.run_mode}"
      end

      def command_line
        [pig_runner_path,run_mode,script_params,script.filename].flatten.join(" ")
      end

      def execute
        ENV['PIG_OPTS'] = [jobconf_options,pig_jobconf_options].flatten.join(" ")
        puts "ENV['PIG_OPTS'] = '%s'" % [ENV['PIG_OPTS']]
        sh command_line
      end

    end
  end
end
