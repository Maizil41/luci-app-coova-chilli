module("luci.controller.coovachilli", package.seeall)
local fs = require "nixio.fs"
local nixio = require "nixio"
local http = require "luci.http"

function index()
    entry({"admin", "services", "coovachilli", "status"}, call("action_status"), _("Status")).leaf = true
    entry({"admin", "services", "coovachilli", "start"}, call("action_start"), _("Start")).leaf = true
    entry({"admin", "services", "coovachilli", "stop"}, call("action_stop"), _("Stop")).leaf = true
    entry({"admin", "services", "coovachilli", "restart"}, call("action_restart"), _("Restart")).leaf = true
    entry({"admin", "services", "coovachilli", "logs"}, call("get_log_content")).leaf = true
end

function action_status()
    local status = false
    local pid = "N/A"

    local output = luci.util.exec("ps | grep '[c]hilli' | awk '{print $1}'")
    local trimmed = output:gsub("%s+", "")

    if trimmed ~= "" and trimmed:match("^%d+$") then
        status = true
        pid = trimmed
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        running = status,
        pid = pid,
        raw_output = output,
        method = "ps | grep '[c]hilli'"
    })
end

function action_start()
    luci.sys.init.start("chilli")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "chilli"))
end

function action_stop()
    luci.sys.init.stop("chilli")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "chilli"))
end

function action_restart()
    luci.sys.init.restart("chilli")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "chilli"))
end
function get_log_content()
    local cmd = "logread | grep chilli"
    local f = io.popen(cmd, "r")  -- Gunakan io.popen, bukan io.open
    if not f then
        luci.http.status(500, "Failed to execute logread command")
        return
    end

    local lines = {}
    for line in f:lines() do
        table.insert(lines, 1, line) -- Baris dibalik urutannya (paling baru di atas)
    end
    f:close()

    luci.http.prepare_content("text/plain")
    luci.http.write(table.concat(lines, "\n"))
end