require 'rails_helper'

RSpec.describe TestCase, type: :model do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  
  describe 'validations' do
    subject { build(:test_case, user: user, organization: organization) }
    
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(3).is_at_most(255) }
    it { should validate_presence_of(:expected_results) }
    
    it 'validates priority inclusion' do
      test_case = build(:test_case, user: user, organization: organization)
      test_case.priority = 'invalid'
      expect { test_case.valid? }.to raise_error(ArgumentError, "'invalid' is not a valid priority")
    end
    
    it 'validates category inclusion' do
      test_case = build(:test_case, user: user, organization: organization)
      test_case.category = 'invalid'
      expect { test_case.valid? }.to raise_error(ArgumentError, "'invalid' is not a valid category")
    end
    
    it 'validates status inclusion' do
      test_case = build(:test_case, user: user, organization: organization)
      test_case.status = 'invalid'
      expect { test_case.valid? }.to raise_error(ArgumentError, "'invalid' is not a valid status")
    end
    
    it 'validates estimated_duration when present' do
      test_case = build(:test_case, estimated_duration: 0, user: user, organization: organization)
      expect(test_case).not_to be_valid
      expect(test_case.errors[:estimated_duration]).to include("must be greater than 0")
      
      test_case.estimated_duration = 301
      expect(test_case).not_to be_valid
      expect(test_case.errors[:estimated_duration]).to include("must be less than or equal to 300")
      
      test_case.estimated_duration = 15
      expect(test_case).to be_valid
    end
  end
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:organization) }
  end
  
  describe 'enums' do
    it 'defines priority enum' do
      expect(TestCase.priorities).to eq({
        'low' => 'low',
        'medium' => 'medium', 
        'high' => 'high',
        'critical' => 'critical'
      })
    end
    
    it 'defines category enum' do
      expect(TestCase.categories.keys).to include('functional', 'ui_ux', 'integration', 'performance', 'security', 'regression')
    end
    
    it 'defines status enum' do
      expect(TestCase.statuses.keys).to include('draft', 'ready', 'in_review', 'approved', 'deprecated')
    end
  end
  
  describe 'scopes' do
    let!(:high_priority_case) { create(:test_case, :high_priority, user: user, organization: organization) }
    let!(:medium_priority_case) { create(:test_case, priority: 'medium', user: user, organization: organization) }
    let!(:ready_case) { create(:test_case, :ready, user: user, organization: organization) }
    
    it 'filters by priority' do
      expect(TestCase.by_priority('high')).to include(high_priority_case)
      expect(TestCase.by_priority('high')).not_to include(medium_priority_case)
    end
    
    it 'filters by status' do
      expect(TestCase.by_status('ready')).to include(ready_case)
      expect(TestCase.by_status('ready')).not_to include(high_priority_case)
    end
    
    it 'orders by recent' do
      older_case = create(:test_case, user: user, organization: organization)
      sleep 0.01 # Ensure different timestamps
      newer_case = create(:test_case, user: user, organization: organization)
      
      expect(TestCase.recent.pluck(:id).first).to eq(newer_case.id)
    end
  end
  
  describe 'tag methods' do
    let(:test_case) { create(:test_case, tags: "login, authentication, regression", user: user, organization: organization) }
    
    it 'parses tag_list correctly' do
      expect(test_case.tag_list).to eq(['login', 'authentication', 'regression'])
    end
    
    it 'handles empty tags' do
      test_case.tags = ""
      expect(test_case.tag_list).to eq([])
    end
    
    it 'sets tags from tag_list' do
      test_case.tag_list = ['ui', 'frontend', 'critical']
      expect(test_case.tags).to eq('ui, frontend, critical')
    end
  end
  
  describe 'step methods' do
    let(:test_case) { create(:test_case, steps: ["Step 1", "Step 2"], user: user, organization: organization) }
    
    it 'returns steps_list correctly' do
      expect(test_case.steps_list).to eq(["Step 1", "Step 2"])
    end
    
    it 'handles empty steps' do
      test_case.steps = []
      expect(test_case.steps_list).to eq([])
    end
    
    it 'adds steps' do
      test_case.add_step("Step 3")
      expect(test_case.steps_list).to eq(["Step 1", "Step 2", "Step 3"])
    end
    
    it 'removes steps' do
      test_case.remove_step(0)
      expect(test_case.steps_list).to eq(["Step 2"])
    end
  end
  
  describe 'badge methods' do
    let(:test_case) { create(:test_case, user: user, organization: organization) }
    
    it 'returns correct priority badge class' do
      test_case.priority = 'critical'
      expect(test_case.priority_badge_class).to eq('badge-error')
      
      test_case.priority = 'high'
      expect(test_case.priority_badge_class).to eq('badge-warning')
      
      test_case.priority = 'medium'
      expect(test_case.priority_badge_class).to eq('badge-info')
      
      test_case.priority = 'low'
      expect(test_case.priority_badge_class).to eq('badge-neutral')
    end
    
    it 'returns correct status badge class' do
      test_case.status = 'approved'
      expect(test_case.status_badge_class).to eq('badge-success')
      
      test_case.status = 'ready'
      expect(test_case.status_badge_class).to eq('badge-info')
      
      test_case.status = 'draft'
      expect(test_case.status_badge_class).to eq('badge-warning')
    end
  end
  
  describe 'defaults' do
    it 'sets default values correctly' do
      test_case = TestCase.new
      expect(test_case.priority).to eq('medium')
      expect(test_case.category).to eq('functional') 
      expect(test_case.status).to eq('draft')
      expect(test_case.steps).to eq([])
      expect(test_case.notes).to eq({})
    end
  end
end
