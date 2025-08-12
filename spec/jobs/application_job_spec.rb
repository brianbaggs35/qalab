require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  it 'inherits from ActiveJob::Base' do
    expect(ApplicationJob.superclass).to eq(ActiveJob::Base)
  end

  it 'has the correct class name' do
    expect(ApplicationJob.name).to eq('ApplicationJob')
  end
end