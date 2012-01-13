module Swineherd
  module HadoopJobconf

    # Translate simplified args to their hairy hadoop equivalents

    Swineherd.config.define :hadoop_home,:description => "Path to hadoop installation; ENV['HADOOP_HOME'] by default. HADOOP_HOME/bin/hadoop is used to run hadoop.", :env_var => 'HADOOP_HOME'

    Swineherd.config.define :max_node_map_tasks,      :description => 'mapred.tasktracker.map.tasks.maximum',:hadoop_jobconf => true,:hadoop_jobconf => true
    Swineherd.config.define :max_node_reduce_tasks,   :description => 'mapred.tasktracker.reduce.tasks.maximum',:hadoop_jobconf => true
    Swineherd.config.define :map_tasks,               :description => 'mapred.map.tasks',:hadoop_jobconf => true
    Swineherd.config.define :reduce_tasks,            :description => 'mapred.reduce.tasks',:hadoop_jobconf => true
    Swineherd.config.define :sort_fields,             :description => 'stream.num.map.output.key.fields',:hadoop_jobconf => true
    Swineherd.config.define :key_field_separator,     :description => 'map.output.key.field.separator',:hadoop_jobconf => true
    Swineherd.config.define :partition_fields,        :description => 'num.key.fields.for.partition',:hadoop_jobconf => true
    Swineherd.config.define :output_field_separator,  :description => 'stream.map.output.field.separator',:hadoop_jobconf => true
    Swineherd.config.define :map_speculative,         :description => 'mapred.map.tasks.speculative.execution',:hadoop_jobconf => true
    Swineherd.config.define :timeout,                 :description => 'mapred.task.timeout',:hadoop_jobconf => true
    Swineherd.config.define :reuse_jvms,              :description => 'mapred.job.reuse.jvm.num.tasks',:hadoop_jobconf => true
    Swineherd.config.define :respect_exit_status,     :description => 'stream.non.zero.exit.is.failure',:hadoop_jobconf => true
    Swineherd.config.define :io_sort_mb,              :description => 'io.sort.mb',:hadoop_jobconf => true
    Swineherd.config.define :io_sort_record_percent,  :description => 'io.sort.record.percent',:hadoop_jobconf => true
    Swineherd.config.define :job_name,                :description => 'mapred.job.name',:hadoop_jobconf => true
    Swineherd.config.define :max_reduces_per_node,    :description => 'mapred.max.reduces.per.node',:hadoop_jobconf => true
    Swineherd.config.define :max_reduces_per_cluster, :description => 'mapred.max.reduces.per.cluster',:hadoop_jobconf => true
    Swineherd.config.define :max_maps_per_node,       :description => 'mapred.max.maps.per.node',:hadoop_jobconf => true
    Swineherd.config.define :max_maps_per_cluster,    :description => 'mapred.max.maps.per.cluster',:hadoop_jobconf => true
    Swineherd.config.define :max_record_length,       :description => 'mapred.linerecordreader.maxlength',:hadoop_jobconf => true # "Safeguards against corrupted data: lines longer than this (in bytes) are treated as bad records.",
    Swineherd.config.define :min_split_size,          :description => 'mapred.min.split.size',:hadoop_jobconf => true
    Swineherd.config.define :noempty,                 :description => "don't create zero-byte reduce files (hadoop mode only)",:hadoop_jobconf => true
    #    end

    def jobconf_options
      #config.hadoop
      config.options_for(:hadoop_jobconf).inject([]){ |options,option| options << jobconf_for(option[0]) }
    end

    #FIXME: Currently doesn't accept arbitrary jobconf commands, like "mapred.min.split.size".
    def jobconf_for option
      unless config[option].nil?
        "-D%s=%s" % [config.definition_of(option)[:description], config[option]]
      end
    end

  end
end
