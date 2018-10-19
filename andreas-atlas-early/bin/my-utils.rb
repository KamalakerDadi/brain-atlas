require 'optparse'

$options = {
  :out => "stdout",
  :verbose => true,
  :fatal => true
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] "

  opts.on("-q", "--quiet", "Run quietly") do |v|
    $options[:verbose] = false
  end
  opts.on("-f", "--fatal", "Stop on first error") do |v|
    $options[:fatal] = v
  end
  opts.on("-o", "--out", "send output to OUT") do |v|
    $options[:out] = v
  end
end.parse!

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

