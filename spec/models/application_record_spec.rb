require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  it 'is an abstract class' do
    expect(ApplicationRecord).to be < ActiveRecord::Base
  end

  it 'can be inherited by other models' do
    expect(User.superclass).to eq(ApplicationRecord)
    expect(Organization.superclass).to eq(ApplicationRecord)
  end
end