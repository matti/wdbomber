RSpec.describe Wdbomber do
  it do
    chromedriver_k = Kommando.new "chromedriver-helper", output: true
    chromedriver_k.run_async
    sleep 1

    Wdbomber.run! "http://localhost:9515", iterations: 3, concurrency: 3, concurrency_delay: 1

    chromedriver_k.kill
  end
end
