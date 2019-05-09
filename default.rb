#!/usr/bin/env ruby

%x(gem list).each_line.grep(/default: /).map(&:chomp).each do |line|
  name, versions = line.split(" ", 2)
  next if name == "bundler"

  versions = versions[1..-2].split(",").map(&:strip)
  default_gems = versions.select { |e| e.start_with? "default: " }
  bundle_gems = versions.size - default_gems.size

  # default gem以外のバージョンがある(default gemが更新されたときなどに発生する)
  if bundle_gems > 0
    puts "gem uninstall #{name}"
    puts "gem update #{name} --default"
  end

  # default gemが複数バージョンある
  if default_gems.size > 1
    default_gems
      .drop(1)
      .map { |e| e.delete_prefix "default: " }
      .map { |e| "$(gem env gemdir)/specifications/default/#{name}-#{e}.gemspec" }
      .each { |e| puts "rm #{e}" }
  end
end
