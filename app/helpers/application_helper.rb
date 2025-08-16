module ApplicationHelper
  def format_duration(seconds)
    return "N/A" if seconds.nil?

    seconds = seconds.to_f
    return "N/A" if seconds <= 0

    if seconds < 60
      # Less than a minute, show seconds with 3 decimal places
      "#{sprintf('%.3f', seconds)}s"
    elsif seconds < 3600
      # Less than an hour, show minutes and seconds
      minutes = (seconds / 60).floor
      remaining_seconds = seconds % 60
      "#{minutes}m #{sprintf('%.3f', remaining_seconds)}s"
    else
      # More than an hour, show hours, minutes, and seconds
      hours = (seconds / 3600).floor
      remaining_minutes = ((seconds % 3600) / 60).floor
      remaining_seconds = seconds % 60
      "#{hours}h #{remaining_minutes}m #{sprintf('%.3f', remaining_seconds)}s"
    end
  end
end
