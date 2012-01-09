module Swineherd
  class PigScript < Script

    #shortcut accessor for setting Pig `-param FOO=bar` command line parameters
    def params
      runner.config.params
    end

    def run_mode=(mode)
      runner.config.run_mode = mode
    end

    def run_mode
      runner.config.run_mode
    end

    def flush!
      runner.config.params.clear
      super
    end

  end
end
