# Setup Capybara for system tests
require 'capybara/rspec'
require 'selenium-webdriver'

# Set up headless Chrome for CI environments
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

# Use headless chrome as the default driver for system tests
Capybara.default_driver = :headless_chrome
Capybara.javascript_driver = :headless_chrome

# Increase wait times for CI environments
Capybara.default_max_wait_time = 10
Capybara.default_normalize_ws = true