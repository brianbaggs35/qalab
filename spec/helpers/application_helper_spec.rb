require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#format_duration' do
    it 'returns "N/A" for nil duration' do
      expect(helper.format_duration(nil)).to eq("N/A")
    end

    it 'returns "N/A" for zero duration' do
      expect(helper.format_duration(0)).to eq("N/A")
    end

    it 'returns "N/A" for negative duration' do
      expect(helper.format_duration(-1)).to eq("N/A")
    end

    it 'formats seconds with 3 decimal places for durations under 1 minute' do
      expect(helper.format_duration(45.123)).to eq("45.123s")
      expect(helper.format_duration(0.001)).to eq("0.001s")
      expect(helper.format_duration(59.999)).to eq("59.999s")
    end

    it 'formats minutes and seconds for durations under 1 hour' do
      expect(helper.format_duration(60)).to eq("1m 0.000s")
      expect(helper.format_duration(90.5)).to eq("1m 30.500s")
      expect(helper.format_duration(3599.123)).to eq("59m 59.123s")
    end

    it 'formats hours, minutes, and seconds for durations over 1 hour' do
      expect(helper.format_duration(3600)).to eq("1h 0m 0.000s")
      expect(helper.format_duration(3661.5)).to eq("1h 1m 1.500s")
      expect(helper.format_duration(7323.456)).to eq("2h 2m 3.456s")
    end

    it 'handles string input by converting to float' do
      expect(helper.format_duration("45.123")).to eq("45.123s")
      expect(helper.format_duration("3661.5")).to eq("1h 1m 1.500s")
    end
  end
end