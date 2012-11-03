
task :default => :build

task :test do
  system "coffee tests/runner.coffee"
end

task :build do
  system "coffee -c ts.coffee"
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
        system "coffee tests/runner.coffee"
      end
    end
  end

  EM.kqueue if EM.kqueue?
  EM.run do
    ["."].collect { |dir|
      Dir.glob(File.dirname(__FILE__) + "/#{dir}/**/*.coffee")
    }.flatten.each do |file|  
      EM.watch_file file, Handler
    end
  end
end