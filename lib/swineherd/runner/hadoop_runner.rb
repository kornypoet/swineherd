module Swineherd
  module Runner
    class HadoopRunner < BaseRunner
      include HadoopJobconf

      register /.*\.rb\.?.*/ #wukong style streaming scripts

      def hadoop_runner_path
        [config.hadoop_home,"bin","hadoop"].join("/")
      end

      def command_line
        # If no reducer_klass and no reduce_command, then skip the reduce phase
        config[:reduce_tasks] = 0 if (! reducer_klass) && (! config[:reduce_command]) && (! config[:reduce_tasks])
        # Input paths join by ','
        input_paths = @input_paths.join(',')
        #
        hadoop_commandline = [
          hadoop_runner_path,
          "jar #{config.hadoop_home}/contrib/streaming/hadoop-*streaming*.jar",
          hadoop_jobconf_options,
          "-D mapred.job.name='#{job_name}'",
          hadoop_other_args,
          "-mapper  '#{mapper_commandline}'",
          "-reducer '#{reducer_commandline}'",
          "-input   '#{input_paths}'",
          "-output  '#{output_path}'",
          hadoop_recycle_env
        ].flatten.compact.join(" \t\\\n  ")
      end

      def hadoop_jobconf_options
        jobconf_options = []
        # Fields hadoop should use to distribute records to reducers
        unless options[:partition_fields].blank?
          jobconf_options += [
            '-partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner',
            jobconf_for(:output_field_separator),
            jobconf_for(:partition_fields),
          ]
        end
        # The fields should hadoop treat as the keys
        jobconf_options += [
          # -partitioner                          org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner \
          # -D mapred.output.key.comparator.class=org.apache.hadoop.mapred.lib.KeyFieldBasedComparator \
          # -D mapred.text.key.comparator.options=-k2,2nr\
          # -D mapred.text.key.partitioner.options=-k1,2\
          # -D mapred.text.key.partitioner.options=\"-k1,$partfields\"
          # -D stream.num.map.output.key.fields=\"$sortfields\"
          #
          # -D stream.map.output.field.separator=\"'/t'\"
          # -D    map.output.key.field.separator=. \
          # -D       mapred.data.field.separator=. \
          # -D map.output.key.value.fields.spec=6,5,1-3:0- \
          # -D reduce.output.key.value.fields.spec=0-2:5- \
          jobconf_for(:key_field_separator),
          jobconf_for(:sort_fields),
        ]
        # Setting the number of mappers and reducers.
        jobconf_options += [
          jobconf_for(:max_node_map_tasks),
          jobconf_for(:max_node_reduce_tasks),
          jobconf_for(:max_reduces_per_node),
          jobconf_for(:max_reduces_per_cluster),
          jobconf_for(:max_maps_per_node),
          jobconf_for(:max_maps_per_cluster),
          jobconf_for(:map_tasks),
          jobconf_for(:reduce_tasks),
          jobconf_for(:min_split_size),
        ]
        jobconf_options.flatten.compact
      end

      def hadoop_other_args
        extra_str_args  = [ config[:extra_args] ]
        extra_str_args               += ' -lazyOutput' if config[:noempty]  # don't create reduce file if no records
        config[:reuse_jvms]          = '-1'     if (config[:reuse_jvms] == true)
        config[:respect_exit_status] = 'false'  if (config[:ignore_exit_status] == true)
        extra_hsh_args = [:map_speculative, :timeout, :reuse_jvms, :respect_exit_status].map{|opt| jobconf(opt)  }
        extra_str_args + extra_hsh_args
      end

      def hadoop_recycle_env
        %w[RUBYLIB].map do |var|
          %Q{-cmdenv '#{var}=#{ENV[var]}'} if ENV[var]
        end.compact
      end

      def execute
        sh command_line
      end

    end
  end
end
