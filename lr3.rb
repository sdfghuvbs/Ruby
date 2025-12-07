# frozen_string_literal: true

require 'find'
require 'digest'
require 'json'

class DuplicateScanner
  def initialize(root_path, ignore_patterns = [])
    @root_path = root_path
    @ignore_patterns = ignore_patterns
    @files_data = []
  end

  def scan
    puts "Scanning directory: #{@root_path}"

    Find.find(@root_path) do |path|
      if should_ignore?(path)
        Find.prune
        next
      end

      next unless File.file?(path)

      size = File.size(path)
      @files_data << { path: path, size: size }
    end

    puts "Scanned #{@files_data.length} files"
    @files_data
  end

  def find_duplicates
    scan if @files_data.empty?

    groups_by_size = @files_data.group_by { |f| f[:size] }
    groups_by_size.select! { |size, files| files.length > 1 && size > 0 }

    duplicate_groups = []

    groups_by_size.each do |size, files|
      hash_groups = {}

      files.each do |file|
        hash = calculate_file_hash(file[:path])
        next if hash.nil?

        hash_groups[hash] ||= []
        hash_groups[hash] << file[:path]
      end

      hash_groups.each do |_, paths|
        if paths.length > 1
          saved_bytes = size * (paths.length - 1)
          duplicate_groups << {
            size_bytes: size,
            saved_if_dedup_bytes: saved_bytes,
            files: paths
          }
        end
      end
    end

    duplicate_groups
  end

  def generate_report(output_file = 'duplicates.json')
    groups = find_duplicates

    report = {
      scanned_files: @files_data.length,
      duplicate_groups: groups.length,
      total_saved_bytes: groups.sum { |g| g[:saved_if_dedup_bytes] },
      groups: groups
    }

    File.write(output_file, JSON.pretty_generate(report))
    puts "Report saved to #{output_file}"
    puts "Found #{groups.length} duplicate groups"
    puts "Total space can be saved: #{format_bytes(report[:total_saved_bytes])}"

    report
  end

  private

  def should_ignore?(path)
    @ignore_patterns.any? { |pattern| path.include?(pattern) }
  end

  def calculate_file_hash(path)
    Digest::SHA256.file(path).hexdigest
  rescue StandardError => e
    puts "Error reading file #{path}: #{e.message}"
    nil
  end

  def format_bytes(bytes)
    return "0 B" if bytes == 0

    units = %w[B KB MB GB TB]
    exp = (Math.log(bytes) / Math.log(1024)).to_i
    exp = [exp, units.length - 1].min

    "%.2f %s" % [bytes.to_f / (1024 ** exp), units[exp]]
  end
end

puts "Enter directory path to scan:"
root_path = gets.chomp

unless Dir.exist?(root_path)
  puts "Directory does not exist!"
  exit
end

ignore_patterns = %w[.git node_modules .idea]
scanner = DuplicateScanner.new(root_path, ignore_patterns)
scanner.generate_report('lab3/duplicates.json')
