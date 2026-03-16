# frozen_string_literal: true

require 'rubocop/rake_task'

desc 'Run RuboCop lint checks'
RuboCop::RakeTask.new(:lint) do |task|
	task.options = ['--display-cop-names', '--extra-details']
	task.options << '--format' << 'github' if ENV['CI']
end

desc 'Run syntax checks on Ruby files'
task :syntax do
	puts '==> Checking syntax...'
	ruby_files = Dir['bin/**/*', 'completions/**/*', 'test/**/*', 'Rakefile', 'Gemfile', '*.gemspec'].select do |f|
		File.file?(f) && (f.end_with?('.rb') || File.open(f) do |file|
			file.readline =~ /ruby/
		rescue
			false
		end)
	end

	ruby_files.each do |file|
		print "Checking #{file}... "
		success = system('ruby', '-c', file, out: File::NULL, err: File::NULL)
		if success
			puts 'OK'
		else
			puts 'FAILED'
			exit 1
		end
	end
end

desc 'Run integration tests'
task :test do
	puts '==> Running integration tests...'
	sh 'bash test/main.sh'
end

desc 'Build the gem'
task :release do
	puts '==> Building gem...'
	sh 'gem build brew-no-quarantine.gemspec'
end

task default: %i[lint syntax test]
