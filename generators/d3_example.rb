require "influxdb"
require "faker"

influxdb = InfluxDB::Client.new "demo",
  username: "user",
  password: "pass",
  host: "localhost",
  port: 8086

WEEK_IN_SECONDS = 7 * 86400

def rand_time
  (Time.now.to_i - (WEEK_IN_SECONDS * rand).floor) * 1000
end

points = []

5_000.times do
  points << {type: "view", email: Faker::Internet.email, time: rand_time()}
end

2_000.times do
  points << {type: "signup", email: Faker::Internet.email, time: rand_time()}  
end

500.times do
  points << {type: "paid", email: Faker::Internet.email, time: rand_time()}
end

puts points[0].inspect
points.each_slice(500) do |data|
  begin
    puts "Writing #{data.length} points."
    influxdb.write_point("events3", data)
  rescue
    retry
  end
end
