require 'rubygems'
require 'cassandra'

include SimpleUUID

twitter = Cassandra.new('Twitter')
user = {"screen_name" => "ughani"}
twitter.insert(:Users, '5', user)
