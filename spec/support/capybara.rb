# Setup Capybara for system tests
require 'capybara/rspec'

# For CI environments, use rack_test driver for faster tests
# This means JavaScript won't work, but basic form interactions will
if ENV['CI'] || ENV['HEADLESS'] || !ENV['BROWSER']
  Capybara.default_driver = :rack_test
  Capybara.javascript_driver = :rack_test
else
  # Local development with browser
  require 'selenium-webdriver'

  Capybara.register_driver :headless_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-web-security')
    options.add_argument('--window-size=1400,1000')

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.default_driver = :headless_chrome
  Capybara.javascript_driver = :headless_chrome
end

# Increase wait times for CI environments
Capybara.default_max_wait_time = 10
Capybara.default_normalize_ws = true
