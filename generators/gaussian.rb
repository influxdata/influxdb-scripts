require "influxdb"

ACTIONS = [
  {mean: 500, stddev: 75, name: "welcome#index", count: 50_000},
  {mean: 1000, stddev: 100, name: "users#new", count: 500},
  {mean: 200, stddev: 10, name: "sessions#create", count: 5000},
  {mean: 5000, stddev: 800, name: "exceptions#create", count: 200},
  {mean: 400, stddev: 10, name: "logs#show", count: 20_000}
]

TIMESPAN = 24*60*60

class RandomGaussian
  def initialize(mean, stddev, rand_helper = lambda { Kernel.rand })
    @rand_helper = rand_helper
    @mean = mean
    @stddev = stddev
    @valid = false
    @next = 0
  end

  def rand
    if @valid then
      @valid = false
      return @next
    else
      @valid = true
      x, y = self.class.gaussian(@mean, @stddev, @rand_helper)
      @next = y
      return x
    end
  end

  private
  def self.gaussian(mean, stddev, rand)
    theta = 2 * Math::PI * rand.call
    rho = Math.sqrt(-2 * Math.log(1 - rand.call))
    scale = stddev * rho
    x = mean + scale * Math.cos(theta)
    y = mean + scale * Math.sin(theta)
    return x, y
  end
end

influxdb = InfluxDB::Client.new "ops",
  username: "user",
  password: "pass",
  host: "sandbox.influxdb.org",
  port: 9061

points = []
ACTIONS.each do |action|
  r = RandomGaussian.new(action[:mean], action[:stddev])
  (action[:count]).times do |n|
    timestamp = Time.now.to_i - (TIMESPAN * rand).floor
    value = r.rand.to_i.abs
    points << {action: action[:name], value: value, time: timestamp*1000}
    puts "#{action[:name]} => #{value}"
  end
end

points.each_slice(10_000) do |data|
  begin
    puts "Writing #{data.length} points."
    influxdb.write_point("transactions", data)
  rescue
    retry
  end
end



