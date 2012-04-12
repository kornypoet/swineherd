# Swineherd

### Script

Given the Pig script `foo.pig.erb`:

```
fips = LOAD '<%= in_path %>' AS (fips_id:int,state_name:chararray);
DUMP fips;
```

In the Ruby interpreter (irb):

```ruby
require 'swineherd'
script = Swineherd::Script.new('foo.pig.erb', :in_path => 'fips_to_state.tsv')
script.run(:map_tasks => 20, :run_mode => 'local') # Uses the PigRunner based upon the filename extension
```

Hadoop and Pig Jobconf settings can be specified at runtime or at a system/user wide level:

/etc/swineherd.yaml
	
```ruby
map_tasks: 10
```

~/swineherd.yaml

```ruby
:map_tasks:15
```

The above `script.run` will interpolate the script variables, pass Hadoop and Pig settings through `PIG_OPTS` and run the following script:

/tmp/1325544799-4248-foo.pig

```
fips = LOAD 'fips_to_state.tsv' AS (fips_id:int,state_name:chararray);
DUMP fips;
```

With this command line:

```
ENV['PIG_OPTS'] = '-Dmapred.map.tasks=20'
/usr/local/share/pig/bin/pig -x local /tmp/1325544799-4248-foo.pig
```

The same script can be run using the swineherd executable:

```
./swineherd --map_tasks=20 --run_mode=local --binding.in_path=fips_to_state.tsv foo.pig.erb
```

Script variables are specified using `--binding`

### Workflow

A workflow is built using rake `task` objects that doing nothing more than run scripts. A workflow

* can be described with a directed dependency graph
* has an `id` which is used to run its tasks idempotently. At the moment it is the responsibility of the running process (or human being) to choose a suitable id.
* manages intermediate outputs by using the `next_output` and `latest_output` methods. See the examples dir for usage.
* A workflow has a working directory in which all intermediate outputs go
** These are named according to the rake task that created them
