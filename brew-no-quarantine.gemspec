# frozen_string_literal: true

module GitVersion
	def self.get
		version = `git describe --tags --dirty --always 2>/dev/null`.strip
		version = '0.0.0' if version.empty?
		version.sub!(/^v/, '')
		version = "0.1.0.#{version}" unless version =~ /^\d/
		version.tr('-', '.')
	end
end

Gem::Specification.new do |spec|
	spec.name = 'brew-no-quarantine'
	spec.version = ENV['VERSION'] || GitVersion.get
	spec.summary = 'A Homebrew wrapper to remove the quarantine attribute from casks.'
	spec.homepage = 'https://github.com/huangyxi/brew-no-quarantine'
	spec.license = 'MIT'

	spec.authors = ['HUANG Yuxi']
	spec.email = ['brew-no-quarantine@hyxi.dev']

	spec.files = Dir['bin/*', 'completions/**/*', 'README.md', 'LICENSE']
	spec.require_paths = ['bin']

	spec.bindir = 'bin'
	spec.executables = ['brew-no-quarantine']

	spec.required_ruby_version = '>= 3.4'

	# No runtime dependencies needed since it uses system 'brew' and 'xattr'
	spec.metadata['rubygems_mfa_required'] = 'true'
end
