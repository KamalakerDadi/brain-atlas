require 'optparse'

$options = {
  :out => "stdout",
  :verbose => true,
  :fatal => true
}

class ProgramArgs
  def initialize(args)
    @args = args

    @opt_parser = OptionParser.new do |opts|
      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-v", "--[no-]verbose", "Verbose output") do |value|
        $options[:verbose] = value
      end
      opts.on("-f", "--[no-]fatal", "Stop on first error") do |value|
        $options[:fatal] = value
      end
      opts.on("-o", "--out", "send output to OUT") do |value|
        $options[:out] = value
      end
    end
  end

  def on
    @opt_parser.on
  end

  def banner(title)
    @opt_parser.banner = title
  end

  def to_s
    @opt_parser.to_s
  end

  def parse!
    @opt_parser.parse!(@args)
  end
end

def log(msg)
  if $options[:verbose]
    puts msg
  end
end

def err(msg)
  puts msg

  if $options[:fatal]
    exit
  end
end


