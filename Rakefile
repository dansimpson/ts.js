

def file_list
  parts = [
    "ts.coffee"
  ].flatten.uniq
end

def bundle files
  files.collect { |file|
    File.open(file).read
  }.join("\r\n")
end

def convert
  system "coffee -o build -c ts.coffee"
end

task :default => :minify

task :test do
  system "coffee tests/runner.coffee"
end

task :minify => :build do
  require "yuicompressor" 
  File.open("build/ts.min.js", "w") do |f|
    f << YUICompressor.compress_js(File.open("build/ts.js").read, :munge => true)
  end
end

task :build do
  convert
end

task :cbuild do
  system "coffee -w -c ts.coffee"
end

desc "Watch files and run the spec, coffee --watch on many + run"
task :autotest => [:test] do

  require "eventmachine"
  
  $last = Time.now

  module Handler
    def file_modified
      if Time.now - $last > 1
        $last = Time.now
        convert
        system "coffee tests/runner.coffee"
      end
    end
  end

  EM.kqueue if EM.kqueue?
  EM.run do
    ["."].collect { |dir|
      Dir.glob(File.dirname(__FILE__) + "/#{dir}/**/*.coffee")
    }.flatten.each do |file|
       puts file
      EM.watch_file file, Handler
    end
  end
end
