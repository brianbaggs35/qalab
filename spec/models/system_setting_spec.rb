require 'rails_helper'

RSpec.describe SystemSetting, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:key) }
    it { should validate_uniqueness_of(:key) }
  end

  describe 'SMTP settings management' do
    describe '.smtp_settings' do
      before do
        SystemSetting.create!(key: 'smtp_address', value: 'smtp.gmail.com')
        SystemSetting.create!(key: 'smtp_port', value: '587')
        SystemSetting.create!(key: 'smtp_username', value: 'test@example.com')
      end

      it 'returns a hash of SMTP settings' do
        settings = SystemSetting.smtp_settings
        expect(settings).to include(
          'address' => 'smtp.gmail.com',
          'port' => '587',
          'username' => 'test@example.com'
        )
      end

      it 'excludes empty values' do
        settings = SystemSetting.smtp_settings
        expect(settings).not_to have_key('password')
        expect(settings).not_to have_key('domain')
      end
    end

    describe '.update_smtp_settings' do
      let(:params) do
        {
          'address' => 'smtp.sendgrid.net',
          'port' => '587',
          'username' => 'apikey',
          'password' => 'secret123',
          'from_email' => 'noreply@example.com'
        }
      end

      it 'creates or updates settings' do
        expect { SystemSetting.update_smtp_settings(params) }
          .to change { SystemSetting.count }.by(5)

        expect(SystemSetting.find_by(key: 'smtp_address').value).to eq('smtp.sendgrid.net')
        expect(SystemSetting.find_by(key: 'smtp_port').value).to eq('587')
        expect(SystemSetting.find_by(key: 'smtp_username').value).to eq('apikey')
      end

      it 'stores passwords in encrypted_value field' do
        SystemSetting.update_smtp_settings(params)
        
        password_setting = SystemSetting.find_by(key: 'smtp_password')
        expect(password_setting.encrypted_value).to eq('secret123')
        expect(password_setting.value).to be_nil
      end

      it 'skips blank values' do
        params_with_blanks = params.merge('domain' => '', 'reply_to_email' => nil)
        
        expect { SystemSetting.update_smtp_settings(params_with_blanks) }
          .to change { SystemSetting.count }.by(5) # Only non-blank values
      end

      it 'calls update_action_mailer_config' do
        expect(SystemSetting).to receive(:update_action_mailer_config)
        SystemSetting.update_smtp_settings(params)
      end
    end

    describe '.get_setting' do
      context 'with regular value' do
        before do
          SystemSetting.create!(key: 'smtp_address', value: 'smtp.gmail.com')
        end

        it 'returns the value' do
          expect(SystemSetting.get_setting('smtp_address')).to eq('smtp.gmail.com')
        end
      end

      context 'with encrypted value' do
        before do
          SystemSetting.create!(key: 'smtp_password', encrypted_value: 'secret123')
        end

        it 'returns the encrypted value' do
          expect(SystemSetting.get_setting('smtp_password')).to eq('secret123')
        end
      end

      context 'with non-existent key' do
        it 'returns nil' do
          expect(SystemSetting.get_setting('non_existent')).to be_nil
        end
      end
    end

    describe '.redis_connected?' do
      context 'when Redis is not defined' do
        before do
          allow(Object).to receive(:defined?).with(Redis).and_return(false)
        end

        it 'returns false' do
          expect(SystemSetting.redis_connected?).to be false
        end
      end

      context 'when Redis URL is not configured' do
        before do
          allow(ENV).to receive(:[]).with('REDIS_URL').and_return(nil)
        end

        it 'returns false' do
          expect(SystemSetting.redis_connected?).to be false
        end
      end

      context 'when Redis is configured but connection fails' do
        before do
          allow(Object).to receive(:defined?).with(Redis).and_return(true)
          allow(ENV).to receive(:[]).with('REDIS_URL').and_return('redis://localhost:6379')
          
          redis_mock = double('Redis')
          allow(Redis).to receive(:new).and_return(redis_mock)
          allow(redis_mock).to receive(:ping).and_raise(StandardError.new('Connection failed'))
        end

        it 'returns false and logs warning' do
          expect(Rails.logger).to receive(:warn).with(/Redis connection failed/)
          expect(SystemSetting.redis_connected?).to be false
        end
      end

      context 'when Redis is properly connected' do
        before do
          allow(Object).to receive(:defined?).with(Redis).and_return(true)
          allow(ENV).to receive(:[]).with('REDIS_URL').and_return('redis://localhost:6379')
          
          redis_mock = double('Redis')
          allow(Redis).to receive(:new).and_return(redis_mock)
          allow(redis_mock).to receive(:ping).and_return('PONG')
        end

        it 'returns true' do
          expect(SystemSetting.redis_connected?).to be true
        end
      end
    end
  end
end
