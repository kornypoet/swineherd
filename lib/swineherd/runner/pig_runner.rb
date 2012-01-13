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
        "-exectype #{config.run_mode}"
      end

      def command_line
        [pig_runner_path,run_mode,param_options_string,script.filename].flatten.join(" ")
      end

      def execute
        ENV['PIG_OPTS'] = [jobconf_options,pig_jobconf_options].flatten.join(" ")
        Logger.new(STDOUT).info "ENV['PIG_OPTS'] = '%s'" % [ENV['PIG_OPTS']]
        #%x["#{command_line}"]
        sh command_line
      end

    end
  end
end
