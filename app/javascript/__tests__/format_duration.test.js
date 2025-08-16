/**
 * @jest-environment jsdom
 */

describe('formatDuration function', () => {
  // Define the function as it would be in the page
  function formatDuration(seconds) {
    if (!seconds || seconds <= 0) return "N/A";
    
    const s = parseFloat(seconds);
    
    if (s < 60) {
      return `${s.toFixed(3)}s`;
    } else if (s < 3600) {
      const minutes = Math.floor(s / 60);
      const remainingSeconds = s % 60;
      return `${minutes}m ${remainingSeconds.toFixed(3)}s`;
    } else {
      const hours = Math.floor(s / 3600);
      const remainingMinutes = Math.floor((s % 3600) / 60);
      const remainingSeconds = s % 60;
      return `${hours}h ${remainingMinutes}m ${remainingSeconds.toFixed(3)}s`;
    }
  }

  test('returns "N/A" for null/undefined/zero values', () => {
    expect(formatDuration(null)).toBe("N/A");
    expect(formatDuration(undefined)).toBe("N/A");
    expect(formatDuration(0)).toBe("N/A");
    expect(formatDuration(-1)).toBe("N/A");
  });

  test('formats seconds with 3 decimal places for durations under 1 minute', () => {
    expect(formatDuration(45.123)).toBe("45.123s");
    expect(formatDuration(0.001)).toBe("0.001s");
    expect(formatDuration(59.999)).toBe("59.999s");
  });

  test('formats minutes and seconds for durations under 1 hour', () => {
    expect(formatDuration(60)).toBe("1m 0.000s");
    expect(formatDuration(90.5)).toBe("1m 30.500s");
    expect(formatDuration(3599.123)).toBe("59m 59.123s");
  });

  test('formats hours, minutes, and seconds for durations over 1 hour', () => {
    expect(formatDuration(3600)).toBe("1h 0m 0.000s");
    expect(formatDuration(3661.5)).toBe("1h 1m 1.500s");
    expect(formatDuration(7323.456)).toBe("2h 2m 3.456s");
  });

  test('handles string input by converting to float', () => {
    expect(formatDuration("45.123")).toBe("45.123s");
    expect(formatDuration("3661.5")).toBe("1h 1m 1.500s");
  });
});