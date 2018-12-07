require "wdbomber/version"
require "selenium-webdriver"

Signal.trap("INT") {
  if $SHUTDOWN_REQUESTED
    puts "ANOTHER CONTROL+C DETECTED - EXITING"
    exit 1
  else
    puts "REQUESTING SHUTDOWN, PLEASE WAIT - HIT ANOTHER CONTROL+C TO FORCE"
    $SHUTDOWN_REQUESTED = true
  end
}

module Wdbomber
  def self.run!(endpoint, iterations:, concurrency:1, concurrency_delay:0)
    STDERR.puts "attacking #{endpoint} #{iterations} times with #{concurrency} bombers"

    desired_capabilities = Selenium::WebDriver::Remote::Capabilities.chrome
    if ENV["SUPERBOT_REGION"]
      desired_capabilities['superOptions'] = {}
      desired_capabilities['superOptions']['region'] = ENV["SUPERBOT_REGION"]
    end

    threads = []
    concurrency.times do |t|
      bomber = t+1
      sleep t*concurrency_delay #for specs

      threads << Thread.new do
        iterations.times do |i|
          if $SHUTDOWN_REQUESTED
            puts "#{bomber}: SHUTDOWN"
            break
          end

          iteration = i+1

          started_at = Time.now
          client = Selenium::WebDriver::Remote::Http::Default.new
          client.read_timeout = 500
          driver = Selenium::WebDriver.for :remote, {
            url: endpoint,
            desired_capabilities: desired_capabilities,
            http_client: client,
          }
          driver.navigate.to "about:blank"
          took = Time.now - started_at

          puts "#{bomber}: took #{took.floor(1)}s (##{iteration}/#{iterations})"
        rescue
          puts "#{bomber}: EXCEPTION (#{iteration}/#{iterations})"
          p $!
          exit 1 unless ENV["WDBOMBER_KEEP_BOMBING"] == "true"
        ensure
          driver&.quit unless ENV["WDBOMBER_NO_QUIT"] == "true"
        end
      end
    end

    threads.each(&:join)
  end
end
