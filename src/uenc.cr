require "uri"

class CLI
  VERSION = "0.1.0"

  property inputs = [] of String | Path | IO
  property? decode_mode = false
  property? encode_eol = false

  def initialize(@decode_mode, opts = ARGV.dup.to_a)
    while opt = opts.shift?
      case opt
      when "--help"
        raise ArgumentError.new "no help defined yet"
      when "--encode-eol"
        @encode_eol = true
      when "--no-encode-eol"
        @encode_eol = false
      when "--"
        while text = opts.shift?
          @inputs << text
        end
      when "-"
        @inputs << STDIN unless @inputs.includes? STDIN
      when "-f", "--file"
        @inputs << Path[opts.shift? || raise ArgumentError.new "#{opt}: expected file name argument"]
      when .starts_with? '-'
        raise ArgumentError.new "#{opt}: unknown option"
      else
        @inputs << opt
      end
    end

    if @inputs.empty?
      raise ArgumentError.new "no inputs given; did you want to give '-' for STDIN?"
    end
  end

  def run
    @inputs.each do |input|
      case input
      in Path
        if encode_eol?
          process File.read(input)
        else
          File.each_line(input) do |line|
            process line
          end
        end
      in IO
        if encode_eol?
          process input.gets_to_end
        else
          input.each_line do |line|
            process line
          end
        end
      in String
        if encode_eol?
          process input
        else
          input.each_line do |line|
            process line
          end
        end
      end
    end
  end

  def process(line)
    if decode_mode?
      puts URI.decode(line)
    else
      puts URI.encode_path_segment(line)
    end
  end
end

begin
  # STDERR.puts "***#{PROGRAM_NAME}***"
  should_decode = false
  if PROGRAM_NAME =~ /dec[^\/]*$/i
    should_decode = true
  end
  cli = CLI.new should_decode
  cli.run
rescue e : ArgumentError
  if STDERR.tty?
    STDERR.print "\e[31;1m[ERROR]\e[0m "
  else
    STDERR.print "[ERROR] "
  end
  STDERR.puts "#{PROGRAM_NAME}: #{e}"
  exit 1
end
