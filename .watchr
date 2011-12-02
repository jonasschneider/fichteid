# vim:set filetype=ruby:
def run(cmd)
  puts cmd
  system cmd
end

def spec(file)
  if File.exists?(file)
    run("spin push #{file}")
  else
    puts("Spec: #{file} does not exist.")
  end
end

watch("spec/.*/*_spec\.rb") do |match|
  puts(match[0])
  spec(match[0])
end

watch("app/(.*)") do |match|
  puts(match)
  spec("spec/requests/app_spec.rb")
end
