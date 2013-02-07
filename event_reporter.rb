###
# EventReporter
# by Kyle Suss
# Completed 2/7/13
###

require "csv"
require "yaml"

puts "EventReporter initialized."

class Queue

  attr_reader :cache
  attr_reader :queue

  def initialize
    @queue = 0
  end

  def command(action, details)
    case action
      when 'count' then puts @queue
      when 'clear' then clear
      when 'print' then print(details)
      when 'save' then save(details)
    end
  end

  def cache(values)
    if values.nil?
      clear
    else
      @cache = values
      @queue = @cache.count
    end
  end

  def get_headers
    if @queue != 0
      csv_headers = []
      @cache[0].keys.each do |key|
        csv_headers << key
      end
    else
      csv_headers = ["Headers are dynamic. Load a file to get some headers."]
    end
    csv_headers
  end

  def save(file_name)
    csv_headers = get_headers
    CSV.open(file_name, "w") do |csv_file|
      csv_file << csv_headers
      if @queue != 0
        row_count = @cache.count
        i=0
        while i < row_count do 
          csv_file << @cache[i].values
          i += 1
        end
      end
    end
  end

  def clean_headings
    clean_headings = []
    @cache[0].keys.each do |key|
      clean_headings << key.gsub("_", " ").upcase
    end
    clean_headings.shift(2)
    clean_headings
  end

  def clear
    @cache = nil
    @queue = 0
  end

  def print(attribute)
    if @cache != nil
      puts clean_headings.join("\t")
      if attribute == "print"
        simple_print
      else
        advanced_print(attribute)
      end
    else
      puts "The queue is empty."
    end

  end

  def simple_print
    @cache.each do |row|
      row_values_array = row.values
      row_values_array.shift(2)
      puts row_values_array.join("\t")
    end
  end

  def advanced_print(attribute)
    sorted_cache = @cache.sort! { |x, y| x[attribute] <=> y[attribute] }
    sorted_cache.each do |row|
      row_values_array = row.values
      row_values_array.shift(2)
      puts row_values_array.join("\t")
    end
  end

end

class DataFile

  attr_reader :default_file
  attr_reader :current_file_path
  attr_reader :people

  def initialize
    @default_file = "event_attendees.csv"
  end

  def set_path(user_file_input)
    if user_file_input.nil?
      @current_file_path = @default_file
    elsif user_file_input[-4..-1] == ".csv" && File.exists?(user_file_input)
      @current_file_path = user_file_input
    else
      puts "Load a file that actually exists, dumbass!"
    end
  end

  def load_file
    contents = CSV.read @current_file_path
    headers = contents.shift.collect {|i| i.to_s.downcase }
    string_data = contents.collect {|row| row.collect {|cell| cell.to_s } }
    @people = string_data.collect {|row| Hash[*headers.zip(row).flatten] }
    clean_zipcode
    clean_phone_number
    puts "Success! Loaded #{@current_file_path} with #{@people.count} rows."
    @people
  end

  def clean_zipcode
    @people.each do |person|
      person["zipcode"] = person["zipcode"].rjust(5,"X")[0..4]
    end
  end

  def clean_phone_number
    @people.each do |person|
      person["homephone"] = person["homephone"].gsub(/[^0-9]/, '')
      
      if person["homephone"].length == 11 && person["homephone"][0] == 1
        person["homephone"] = person["homephone"][1..-1]
      elsif person["homephone"].length > 11 || person["homephone"].length < 10
        person["homephone"] = "XXXXXXXXXX"
      end
    end
  end

  def find_in_file(attribute, criteria)
    if @current_file_path.nil?
      puts "Load a file, idiot!"
    else
      @people.select{|person| person[attribute].match(/^\s?#{(criteria)}\s?$/i)}
    end
  end

  def to_s
    @current_file_path
  end

end

def help_user(command)
  yaml = YAML.load(File.open("help.yml"))
  case command
    when ''
      i=0
      while i < yaml["help"].count do
        puts "#{yaml["help"].keys[i]}: #{yaml["help"].values[i]}"
        i += 1
      end
    when 'load' then puts yaml["help"]["load"]
    when 'queue count' then puts yaml["help"]["queue count"]
    when 'queue clear' then puts yaml["help"]["queue clear"]
    when 'queue print' then puts yaml["help"]["queue print"]
    when 'find' then puts yaml["help"]["find"]
  end
end

def run
  queue = Queue.new
  data_file = DataFile.new
  command = ""
  while command != "quit"
    printf "Enter command: "
    input = gets.chomp
    parts = input.split(" ")
    command = parts[0]
    case command
      when 'quit' then puts "Goodbye"
      when 'queue' then queue.command(parts[1], parts[-1])
      when 'load'
        begin
          the_file = data_file.set_path(parts[1])
          if the_file
            data_file.load_file
          end
        end
      when 'find'
        query = data_file.find_in_file(parts[1], parts[2..-1].join(" "))
        queue.cache(query)
      when 'help' then help_user(parts[1..-1].join(" "))
      else
        puts "Sorry, I don't know how to #{command}!"
    end
  end
end

run
