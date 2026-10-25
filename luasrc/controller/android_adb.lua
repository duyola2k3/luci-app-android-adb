module("luci.controller.android_adb", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/android_adb") then return end
    local page = entry({"admin", "services", "android-adb"}, alias("admin", "services", "android-adb", "overview"), _("Android ADB"), 60)
    page.dependent = true
    entry({"admin", "services", "android-adb", "overview"}, template("android_adb/overview"), _("Overview"), 1)
    entry({"admin", "services", "android-adb", "status"}, call("action_status")).leaf = true
    entry({"admin", "services", "android-adb", "airplane"}, call("action_airplane")).leaf = true
end

local function config()
    local s = require("luci.model.uci").cursor():get_all("android_adb", "main") or {}
    local host = s.host or ""
    local port = tonumber(s.port or "5555")
    if not host:match("^[%w%.:%-]+$") or not port or port < 1 or port > 65535 then
        return nil, "Cấu hình địa chỉ Android không hợp lệ"
    end
    return host .. ":" .. port
end

local function run(argv)
    local p = io.popen("/usr/bin/adb " .. argv .. " 2>&1", "r")
    if not p then return nil, "Không chạy được ADB" end
    local output = p:read("*a") or ""
    local ok = p:close()
    if not ok then return nil, output end
    return output
end

local function exec_device(host, cmd)
    -- Các câu lệnh ở đây là hằng số do plugin định nghĩa, không nhận command từ HTTP.
    local target = "-s " .. luci.util.shellquote(host) .. " shell " .. luci.util.shellquote(cmd)
    return run(target)
end

local function json(data)
    luci.http.prepare_content("application/json")
    luci.http.write_json(data)
end

function action_status()
    local host, err = config()
    if not host then return json({ok=false, error=err}) end
    local connected, e = run("connect " .. luci.util.shellquote(host))
    if not connected then return json({ok=false, error=e or "Không kết nối được thiết bị"}) end
    local state, se = exec_device(host, "dumpsys battery")
    if not state then return json({ok=false, error=se}) end
    local level = state:match("level:%s*(%d+)")
    local scale = state:match("scale:%s*(%d+)")
    local status = state:match("status:%s*(%d+)")
    local plugged = state:match("plugged:%s*(%d+)")
    local airplane = exec_device(host, "settings get global airplane_mode_on")
    local sim = exec_device(host, "getprop gsm.sim.state")
    local imei = exec_device(host, "getprop gsm.operator.alpha")
    json({ok=true, host=host, battery=tonumber(level), battery_scale=tonumber(scale) or 100,
          battery_status=tonumber(status), charging=tonumber(plugged or "0") ~= 0,
          airplane=(airplane or ""):match("1") ~= nil,
          sim=sim and sim:gsub("[%c]", " "):gsub("%s+$", "") or "Không đọc được",
          carrier=imei and imei:gsub("[%c]", " "):gsub("%s+$", "") or "Không đọc được",
          adb=connected:gsub("[%c]", " "):gsub("%s+$", "")})
end

function action_airplane()
    local value = luci.http.formvalue("enabled")
    if value ~= "0" and value ~= "1" then return json({ok=false, error="Giá trị enabled phải là 0 hoặc 1"}) end
    local host, err = config()
    if not host then return json({ok=false, error=err}) end
    local connected, e = run("connect " .. luci.util.shellquote(host))
    if not connected then return json({ok=false, error=e or "Không kết nối được thiết bị"}) end
    local n = value == "1" and "1" or "0"
    local out, se = exec_device(host, "settings put global airplane_mode_on " .. n .. " && am broadcast -a android.intent.action.AIRPLANE_MODE --ez state " .. n)
    if not out then return json({ok=false, error=se or "Android từ chối lệnh"}) end
    json({ok=true, message="Đã gửi lệnh. Kết quả phụ thuộc quyền ADB và phiên bản Android."})
end
