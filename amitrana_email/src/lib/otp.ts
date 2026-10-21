export function generateOtp(digits = 6) {
  const max = 10 ** digits;
  return String(Math.floor(Math.random() * (max - 1)) + 1).padStart(digits, '0');
}

export function getOtpExpiryMinutes() {
  return Number(process.env.OTP_TTL_MINUTES || '10');
}
