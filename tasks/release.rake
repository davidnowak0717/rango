# encoding: utf-8

desc "Release new version of rango"
task release: ["release:tag", "release:gemcutter", "release:twitter"]

namespace :release do
  desc "Create Git tag"
  task :tag do
    puts "Creating new git tag #{Rango::VERSION} and pushing it online ..."
    sh "git tag -a -m 'Version #{Rango::VERSION}' #{Rango::VERSION}"
    sh "git push --tags"
    puts "Tag #{Rango::VERSION} was created and pushed to GitHub."
  end

  desc "Push gem to Gemcutter"
  task :gemcutter do
    puts "Pushing to Gemcutter ..."
    sh "gem push #{Dir["*.gem"].last}"
  end

  desc "Send message to Twitter"
  task :twitter, :password do
    message = "Rango #{Rango::VERSION} have been just released! Install via RubyGems from RubyForge or GitHub!"
    %x[curl --basic --user RangoProject:#{password} --data status="#{message}" http://twitter.com/statuses/update.xml > /dev/null]
    puts "Message have been sent to Twitter"
  end
end

desc "Create and push prerelease gem"
task :prerelease => "build:prerelease" do
  puts "Pushing to Gemcutter ..."
  sh "gem push #{Dir["*.pre.gem"].last}"
end

dependencies = FileList["vendor/*/.git"].sub(/\/\.git$/, "")

task "deps.rip" do
  commits = Hash.new
  commits = dependencies.inject(Hash.new) do |hash, path|
    Dir.chdir(path) do
      revision = %x(git show | head -1).chomp.sub("commit ", "")
      hash[File.basename(path)] = revision
      hash
    end
  end
  template = File.read("deps.rip.rbe")
  deps_rip = eval("%Q{#{template}}")
  File.open("deps.rip", "w") do |file|
    file.puts(deps_rip)
  end
  sh "chmod +x deps.rip"
  sh "git commit deps.rip -m 'Updated deps.rip'"
end
