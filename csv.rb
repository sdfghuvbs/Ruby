require 'csv'
require 'time'
require 'bigdecimal'

CASTERS = {
  int:     ->(value) { value.to_i rescue nil },
  decimal: ->(value) { BigDecimal(value) rescue nil },
  time:    ->(value) { Time.parse(value) rescue nil }
}.freeze

class StreamingCsvParser
  def initialize(file_path, schema)
    @file_path = file_path
    @schema = schema
  end

  def parse
    CSV.foreach(@file_path, headers: true, header_converters: :symbol) do |row|
      data = row.to_h

      data.each_with_index do |(header, value), index|
        caster_key = @schema[index]

        if caster_key && CASTERS[caster_key]
          data[header] = CASTERS[caster_key].call(value)
        end
      end

      yield data
    end
  end
end

csv_content = <<~CSV
  id,amount,timestamp,name
  1,123.45,2023-10-23 10:00:00,Product A
  2,99.99,2023-10-23 11:30:00,Product B
  3,456.78,invalid_time,Product C
  4,,2023-10-23 13:00:00,Product D
CSV

file_name = 'temp_data.csv'
File.write(file_name, csv_content)

SCHEMA = {
  0 => :int,
  1 => :decimal,
  2 => :time
}.freeze

parser = StreamingCsvParser.new(file_name, SCHEMA)

puts "--- Початок стрімінгового парсингу ---"

parser.parse do |record|
  puts "Оброблено запис:"
  puts "  ID:      #{record[:id].inspect} (#{record[:id].class})"
  puts "  Amount:  #{record[:amount].inspect} (#{record[:amount].class})"
  puts "  Time:    #{record[:timestamp].inspect} (#{record[:timestamp].class})"
  puts "  Name:    #{record[:name].inspect} (#{record[:name].class})"
  puts "---"
end

puts "--- Кінець парсингу ---"

File.delete(file_name) rescue nil