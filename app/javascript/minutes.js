// 時刻。「10:12」も「1012」も 0 時から 612 分。24 時を超えてもよい
export const clockToMinutes = (text) => {
  const m = text.trim().match(/^(-?\d+):?(\d{2})$/)
  return m ? parseInt(m[1]) * 60 + parseInt(m[2]) : null
}

// 長さ。「1:30」も「90」も 90 分
export const durationToMinutes = (text) => {
  const m = text.trim().match(/^(\d+):(\d{2})$/)
  if (m) return parseInt(m[1]) * 60 + parseInt(m[2])
  return /^\d+$/.test(text.trim()) ? parseInt(text) : null
}

export const toHM = (minutes) => `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, "0")}`
