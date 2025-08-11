gg.setVisible(false)
gg.clearResults()

-- 🧩 Konfigurasi dasar
local libName = "libcsharp.so"
local offset = 0x1C8146C  -- Game Offset

-- 🔧 Patch Radar Map
local patchCode = {0x52800020, 0xD65F03C0}
local originalCode = {}

-- 🔍 Cari base address hanya pada segmen aman (r-xp atau Xa)
local function findBase(lib)
  local ranges = gg.getRangesList(lib)
  if not ranges or #ranges == 0 then return nil end
  for _, v in ipairs(ranges) do
    if v.type == "r-xp" or v.state == "Xa" then
      if v.start and v['end'] then
        return v.start
      end
    end
  end
  return nil
end

-- ⛑️ Fungsi patching aman
local function doPatch(enable)
  local base = findBase(libName)
  if not base then
    gg.alert("❌ Library belum termuat: " .. libName .. "\nTunggu sampai masuk gameplay.")
    return
  end

  local addr = base + offset

  if enable then
    if #originalCode == 0 then
      -- Simpan instruksi asli hanya jika belum pernah
      originalCode = gg.getValues({
        {address = addr, flags = gg.TYPE_QWORD},
        {address = addr + 4, flags = gg.TYPE_QWORD}
      })
    end

    gg.setValues({
      {address = addr, flags = gg.TYPE_QWORD, value = patchCode[1]},
      {address = addr + 4, flags = gg.TYPE_QWORD, value = patchCode[2]}
    })
    gg.toast("✅ Patch ON berhasil")
  else
    if #originalCode == 0 then
      gg.toast("⚠️ Belum ada data asli. Patch tidak dikembalikan.")
      return
    end

    gg.setValues(originalCode)
    gg.toast("🔁 Patch OFF berhasil")
  end
end

-- ⏳ Tunggu hingga library valid tersedia
local function waitForLib()
  while true do
    local base = findBase(libName)
    if base then
      gg.toast("✅ Library ditemukan: Siap Patch")
      return
    end
    gg.toast("⏳ Menunggu " .. libName .. " dimuat...")
    gg.sleep(2000)
  end
end

-- 🎛️ UI Menu
local function menu()
  local choice = gg.choice({
    "✅ Aktifkan Patch",
    "❌ Kembalikan ke asli",
    "🚪 Keluar script"
  }, nil, "🛡️ Mobile Legends Maphack/Radarmap")

  if choice == 1 then
    waitForLib()
    doPatch(true)
  elseif choice == 2 then
    doPatch(false)
  elseif choice == 3 then
    os.exit()
  end
end

-- 🔄 Loop pemanggilan menu saat GG visible
while true do
  if gg.isVisible(true) then
    gg.setVisible(false)
    menu()
  end
  gg.sleep(100)
end