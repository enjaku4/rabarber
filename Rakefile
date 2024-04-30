# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: [:spec, :rubocop]

namespace :todo do
  task :check do
    files_with_todo = []
    total_files = 0
    root_dir = Dir.pwd

    puts "Checking for TODOs...\n\n"

    Dir.glob(File.join(root_dir, "**", "*")) do |file|
      next if File.directory?(file) || File.basename(file) == "Rakefile" || file.include?("vendor")

      total_files += 1

      has_todo = false

      File.foreach(file).with_index do |line, line_num|
        if line.include?("TODO")
          relative_file_path = Pathname.new(file).relative_path_from(Pathname.new(root_dir)).to_s
          files_with_todo << "\e[36m#{relative_file_path}:#{line_num + 1}\e[0m: #{line.strip}"
          has_todo = true
        end
      end

      print has_todo ? "\e[31mF\e[0m" : "\e[32m.\e[0m"
    end

    puts "\n\n"

    if files_with_todo.empty?
      puts "#{total_files} files checked, \e[32mno TODOs found\e[0m"
      exit(0)
    else
      puts "TODOs:\n\n"
      puts "#{files_with_todo.join("\n")}\n\n"
      puts "#{total_files} files checked, \e[31m#{files_with_todo.size} TODOs found\e[0m"
      exit(1)
    end
  end
end
