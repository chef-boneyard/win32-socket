require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include('**/*.gem', '**/*.log')

namespace 'gem' do
  desc "Create the win32-socket gem"
  task :create => [:clean] do
    require 'rubygems/package'
    Dir["*.gem"].each{ |f| File.delete(f) }
    spec = eval(IO.read('win32-socket.gemspec'))
    Gem::Package.build(spec)
  end
  
  desc "Install the win32-socket gem"
  task :install => [:create] do
    file = Dir["*.gem"].first
    sh "gem install -l #{file}"
  end
end

namespace 'test' do
  desc "Run the singleton tests"
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.verbose = true
    t.warning = true
    t.test_files = FileList['test/**/*.rb']
  end

  Rake::TestTask.new('instance') do |t|
    t.libs << 'test'
    t.verbose = true
    t.warning = true
    t.test_files = FileList['test/singleton/*.rb']
  end

  Rake::TestTask.new('singleton') do |t|
    t.libs << 'test'
    t.verbose = true
    t.warning = true
    t.test_files = FileList['test/singleton/*.rb']
  end
end

task :default => ['test:all']
