# The class takes an array of files and can calculate
# their differences using LCS algorithm (diff-lcs gem required)
# Author::    Oleg Yakovenko  (mailto:olegykz@gmail.com)

class Differ
  require 'diff-lcs'

  ##
  # Create new differ instance
  #
  # At least two files should be specified as arguments
  # otherwise ArgumentError will be raised

  def initialize(*files)
    files.size > 1 or raise ArgumentError.new("At least two files should be specified")

    @files = files

    @base_filename = files.shift
    @base_file = -> { @data ||= get_file_data(@base_filename) }

    @total_diff = []
  end

  # Get raw diff data for further processing
  # ==== Options
  #
  # * +:force_reload+ - boolean - reload files contents
  def get_diff(options = {})
    return @total_diff if @total_diff.any? && !options[:force_reload]

    sample = options[:force_reload] ? get_file_data(@base_filename) : @base_file.call

    @total_diff = []
    @files.each do |other|
      sdiff = Diff::LCS.sdiff(sample, get_file_data(other))

      sdiff.each_with_index do |diff_line, line_num|
        @total_diff[line_num] ||= []
        @total_diff[line_num] << process_diff_line(*diff_line)
      end
    end

    @total_diff
  end

  # Get pretty-formatted output
  # ==== Options
  #
  # * +:force_reload+ - boolean - reload files contents
  def to_s(options = {})
    get_diff(options) if options[:force_reload] || !@total_diff.any?

    @total_diff.each_with_index.collect do |line, line_num|
      str_data = line.collect { |f_diff| f_diff.join(" ") }.join(";")
      "#{line_num.succ}. #{str_data}"
    end.join("\n")
  end

  # Nope, we won't print files data, just show object_id
  def inspect
    "#{self.class}:#{object_id}>"
  end

  private

  def get_file_data(file)
    # Debug purposes
    puts "Loading #{file}"

    File.readlines(file).map(&:strip)
  rescue => e
    raise "Unable to process #{file}:\n#{e.message}"
  end

  def process_diff_line(operator, line1, line2)
    case operator
      when "!"
        ["*", "#{line1.last}|#{line2.last}"]
      when "-", "+"
        [operator, line1.last || line2.last]
      when "="
        ["", line1.last]
      else
        ['? possible diff-lcs bug ?']
      end
  end

end
