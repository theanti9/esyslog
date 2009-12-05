require 'rake/clean'

ERLC_FLAGS = "-Iinclude +warn_unused_vars +warn_unused_import"

GENERATED = ["parser/esyslog_config_lexer.erl",
             "parser/esyslog_config_parser.erl"]
SRC = FileList['src/*.erl']
SRC.include(GENERATED)
OBJ = SRC.pathmap("%{src,ebin}X.beam")
(["ebin/*.beam", "ebin/*.app"] + GENERATED).each { |f| CLEAN.include(f) }

directory 'ebin'
directory 'doc'

file "parser/esyslog_config_lexer.erl" => ["parser/esyslog_config_lexer.xrl"] do |t|
  sh "erl -noshell -run leex file #{t.name.gsub('.erl', '')} -run init stop"
  sh "erlc -D EUNIT -pa ebin -W #{ERLC_FLAGS} -o ebin #{t.name}"
end

file "parser/esyslog_config_parser.erl" => ["parser/esyslog_config_parser.yrl"] do |t|
  sh "erl -noshell -run yecc file #{t.name.gsub('.erl', '')} -run init stop"
  sh "erlc -D EUNIT -pa ebin -W #{ERLC_FLAGS} -o ebin #{t.name}"
end

file "ebin/esyslog.app" => ["etc/esyslog.app"] do |t|
  cp t.prerequisites.first, t.name
end  

task :app => [:generate, :compile, "ebin/esyslog.app"]
task :generate => ["parser/esyslog_config_lexer.erl",
                   "parser/esyslog_config_parser.erl"]
task :compile => ["ebin"] do
  sh "erlc -D EUNIT -pa ebin -W #{ERLC_FLAGS} -o ebin #{SRC.join(" ")}"
end
task :default => :app

task :test => [:app] do
  puts "Modules under test:"
  OBJ.each do |obj|
    obj[%r{.*/(.*).beam}]
    mod = $1
    test_output = `erl -pa ebin -run #{mod} test -run init stop`

    puts "#{mod}: #{test_output}"
  end
end

task :start => [:app] do
  sh "erl -sname esyslog -pa ebin -s esyslog -run init stop"
end

desc "Generate Documentation"
task :edoc => ["doc"] do
  cd "doc" do
    sh "erl -noshell -run edoc files ../#{SRC.join(" ../")} -run init stop"
  end
end


