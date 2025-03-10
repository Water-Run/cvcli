--[[
cvcli项目源码

Author: WaterRun
Date: 2025-03-10
File: cvcli.lua
]]

-- 全局常量
YML_FILENAME = 'cvcli.yml'
VERSION = 0.1

-- ============== 工具函数 ==============

-- 标准化的提示信息  
-- @param info: 信息的内容
-- @oaram is_err: 是否为异常,布尔值或nil(置空)
local function cvcli_std_note(info, is_err)
    if is_err then
        error(">>> ERR:" .. info .. " <<<")
    else
        print("---" .. info .. "---")
    end
end

-- 获取当前操作系统信息
-- @return: 操作系统类型字符串
local function get_os_env()
    return "win"
end

-- 操作系统相关的剪贴板操作
-- 将文本写入剪贴板
-- @param text: 待写入剪贴板的文本
-- @return: 是否成功，布尔值
local function set_clipboard(text)
    local success = false
    
    -- Windows剪贴板操作
    local tempfile = os.tmpname()
    local file = io.open(tempfile, "w")
    if file then
        file:write(text)
        file:close()
        
        -- 使用powershell命令将文件内容写入剪贴板
        local cmd = 'powershell -command "Get-Content \'' .. tempfile .. '\' | Set-Clipboard"'
        local result = os.execute(cmd)
        os.remove(tempfile)
        success = (result == 0 or result == true)
    end
    
    return success
end

-- 从剪贴板读取文本
-- @return: 剪贴板内容，字符串或nil
local function get_clipboard()
    local text = nil
    
    -- Windows剪贴板操作
    local tempfile = os.tmpname()
    -- 使用powershell命令读取剪贴板内容到文件
    local cmd = 'powershell -command "Get-Clipboard | Out-File -Encoding utf8 \'' .. tempfile .. '\'"'
    local result = os.execute(cmd)
    
    if result == 0 or result == true then
        local file = io.open(tempfile, "r")
        if file then
            text = file:read("*all")
            file:close()
        end
        os.remove(tempfile)
    end
    
    return text
end

-- ============== YML文件操作 ==============

-- 检查键是否合法
-- @param key: 待检查的键
-- @return: 是否合法，布尔值以及错误信息
local function is_valid_key(key)
    -- 检查是否为空
    if not key or key == "" then
        return false, "键不能为空"
    end
    
    -- 检查长度
    if #key > 16 then
        return false, "键不能超过16个字符"
    end
    
    -- 检查是否以连续的三个'-'开头
    if key:match("^%-%-%-") and key ~= "---last---" then
        return false, "键不能以连续的三个'-'开头（这是cvcli的保留字）"
    end
    
    -- 检查是否包含特殊字符（空格等）
    if key:match("%s") then
        return false, "键不能包含空格"
    end
    
    -- 检查是否是保留字
    local reserved_keys = {
        "-w", "-wv", "-wl", "-wvl", "-wr", "-wvlr", "-l", "-mk", "-mv", "-cc", "-cr"
    }
    
    for _, reserved in ipairs(reserved_keys) do
        if key == reserved then
            return false, "键不能是保留字: " .. reserved
        end
    end
    
    return true, nil
end

-- 检查YML文件是否合法
-- @return: 是否合法，数据表，错误信息
local function check_yml_valid()
    -- 检查文件是否存在且可读
    local file = io.open(YML_FILENAME, "r")
    if not file then
        -- 尝试创建文件并添加默认内容
        local create_file = io.open(YML_FILENAME, "w")
        if not create_file then
            return false, nil, "YML文件不存在且无法创建.检查权限"
        end
        create_file:write("---last---: default\n")
        create_file:close()
        
        file = io.open(YML_FILENAME, "r")
        if not file then
            return false, nil, "YML文件创建后仍无法读取.检查权限"
        end
    end
    
    -- 读取文件内容
    local content = file:read("*all")
    file:close()
    
    -- 解析YAML内容
    local data = {}
    local keys = {}
    local has_last_key = false
    
    for line in content:gmatch("[^\r\n]+") do
        local k, v = line:match("^%s*([^:]+)%s*:%s*(.+)%s*$")
        
        -- 检查格式是否正确
        if not k or not v then
            return false, nil, "YML文件格式错误，不是标准的键值对格式"
        end
        
        -- 检查键是否合法
        local valid, err_msg = is_valid_key(k)
        if not valid and k ~= "---last---" then
            return false, nil, "键 '" .. k .. "' " .. err_msg
        end
        
        -- 检查是否存在重复键
        if keys[k] then
            return false, nil, "YML文件中存在重复的键: " .. k
        end
        
        -- 记录键
        keys[k] = true
        data[k] = v
        
        -- 检查是否包含---last---键
        if k == "---last---" then
            has_last_key = true
        end
    end
    
    -- 检查是否包含---last---键
    if not has_last_key then
        return false, data, "YML文件缺少必需的---last---键"
    end
    
    -- 检查文件是否可写
    file = io.open(YML_FILENAME, "a")
    if not file then
        return false, data, "YML文件不可写入.检查权限"
    end
    file:close()
    
    return true, data, nil
end

-- 确保YML文件有效，如不有效则尝试修复
-- @return: 是否有效，数据表，错误信息
local function ensure_yml_valid()
    local valid, data, err_msg = check_yml_valid()
    
    if not valid then
        -- 如果已经有数据，尝试修复文件
        if data then
            -- 确保有---last---键
            data["---last---"] = "default"
            
            -- 写回文件
            local file = io.open(YML_FILENAME, "w")
            if file then
                for k, v in pairs(data) do
                    -- 再次检查键的有效性
                    local key_valid, _ = is_valid_key(k)
                    if key_valid or k == "---last---" then
                        file:write(k .. ": " .. tostring(v) .. "\n")
                    end
                end
                file:close()
                
                -- 重新检查
                return check_yml_valid()
            else
                return false, nil, "无法修复YML文件.检查权限"
            end
        else
            -- 尝试创建新文件
            local file = io.open(YML_FILENAME, "w")
            if file then
                file:write("---last---: default\n")
                file:close()
                
                -- 重新检查
                return check_yml_valid()
            else
                return false, nil, "无法创建YML文件.检查权限"
            end
        end
    end
    
    return valid, data, err_msg
end

-- 重建YML文件
-- @return: 是否成功
local function rebuild_yml()
    local file = io.open(YML_FILENAME, "w")
    if not file then
        cvcli_std_note("无法创建YML文件.检查权限", true)
        return false
    end
    
    file:write("---last---: default\n")
    file:close()
    return true
end

-- ============== 核心功能函数 ==============

-- 写入键值对  
-- @param key: 待写入的键
-- @param value: 待写入的值  
-- @param readonly: 是否为只读模式(不可新建键),布尔值或nil(置空)
local function cvcli_write(key, value, readonly)
    -- 检查键是否合法
    local valid, err_msg = is_valid_key(key)
    if not valid then
        cvcli_std_note(err_msg, true)
        return false
    end
    
    -- 检查YML文件是否有效
    local yml_valid, data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ".运行`cvcli`指令重新构建", true)
        return false
    end
    
    -- 检查只读模式
    if readonly and data[key] == nil then
        cvcli_std_note("只读模式限制不可新建键", true)
        return false
    end
    
    -- 更新数据
    data[key] = value
    
    -- 如果不是---last---键，则更新---last---为当前键
    if key ~= "---last---" then
        data["---last---"] = key
    end
    
    -- 写回文件
    local file = io.open(YML_FILENAME, "w")
    if file then
        for k, v in pairs(data) do
            file:write(k .. ": " .. tostring(v) .. "\n")
        end
        file:close()
        print("已写入键 '" .. key .. "' 的值")
        return true
    else
        cvcli_std_note("在重写入时出现错误.检查权限", true)
        return false
    end
end

-- 读取键值对  
-- @param key: 待读取的键
-- @return: 读出的值，如果键不存在则返回nil
local function cvcli_read(key)
    -- 检查参数
    if not key then
        cvcli_std_note("键不能为空", true)
        return nil
    end
    
    -- 检查YML文件是否有效
    local yml_valid, data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ".运行`cvcli`指令重新构建", true)
        return nil
    end
    
    -- 直接从数据中获取值
    if data[key] then
        -- 如果不是---last---键，则更新---last---为当前键
        if key ~= "---last---" then
            -- 写回文件以更新---last---
            data["---last---"] = key
            local file = io.open(YML_FILENAME, "w")
            if file then
                for k, v in pairs(data) do
                    file:write(k .. ": " .. tostring(v) .. "\n")
                end
                file:close()
            end
        end
        
        -- 将读取到的值复制到剪贴板
        local value = data[key]
        if set_clipboard(value) then
            print("已读取键 '" .. key .. "' 的值并复制到剪贴板: " .. value)
        else
            print("已读取键 '" .. key .. "' 的值: " .. value)
            cvcli_std_note("复制到剪贴板失败", true)
        end
        
        return value
    else
        cvcli_std_note("指定的键不存在", true)
        return nil
    end
end

-- 读取上次使用的键
-- @return: 上次使用的键的值，如果不存在则返回nil
local function cvcli_read_last()
    -- 检查YML文件是否有效
    local yml_valid, data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ".运行`cvcli`指令重新构建", true)
        return nil
    end
    
    -- 获取上次使用的键
    local last_key = data["---last---"]
    if last_key == "default" or not data[last_key] then
        cvcli_std_note("没有有效的上次使用记录", true)
        return nil
    end
    
    -- 读取上次使用的键的值
    local value = data[last_key]
    
    -- 将读取到的值复制到剪贴板
    if set_clipboard(value) then
        print("已读取上次使用的键 '" .. last_key .. "' 的值并复制到剪贴板: " .. value)
    else
        print("已读取上次使用的键 '" .. last_key .. "' 的值: " .. value)
        cvcli_std_note("复制到剪贴板失败", true)
    end
    
    return value
end

-- 删除键值对
-- @param key: 待删除的键
-- @return: 操作是否成功，布尔值
local function cvcli_remove(key)
    -- 检查参数
    if not key then
        cvcli_std_note("键不能为空", true)
        return false
    end
    
    -- 不允许删除---last---键
    if key == "---last---" then
        cvcli_std_note("不能删除系统保留键---last---", true)
        return false
    end
    
    -- 检查YML文件是否有效
    local yml_valid, data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ".运行`cvcli`指令重新构建", true)
        return false
    end
    
    -- 检查键是否存在
    if not data[key] then
        cvcli_std_note("指定的键不存在", true)
        return false
    end
    
    -- 删除键
    data[key] = nil
    
    -- 如果删除的键是last键记录的值，重置last键
    if data["---last---"] == key then
        data["---last---"] = "default"
    end
    
    -- 写回文件
    local file = io.open(YML_FILENAME, "w")
    if file then
        for k, v in pairs(data) do
            file:write(k .. ": " .. tostring(v) .. "\n")
        end
        file:close()
        print("已删除键 '" .. key .. "'")
        return true
    else
        cvcli_std_note("在重写入时出现错误.检查权限", true)
        return false
    end
end

-- 正则匹配并格式化输出
-- @param target: 匹配的对象: key 或 value
-- @param re_match: 匹配的正则表达式
local function cvcli_match_show(target, re_match)
    -- 检查参数
    if not target or not re_match then
        cvcli_std_note("参数不能为空", true)
        return false
    end
    
    -- 确保target是key或value
    if target ~= "key" and target ~= "value" then
        cvcli_std_note("匹配对象必须是'key'或'value'", true)
        return false
    end
    
    -- 检查YML文件是否有效
    local yml_valid, data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ".运行`cvcli`指令重新构建", true)
        return false
    end
    
    -- 存储匹配的结果
    local matches = {}
    local count = 0
    
    -- 搜索匹配项
    for k, v in pairs(data) do
        if target == "key" and k:match(re_match) then
            count = count + 1
            matches[count] = {key = k, value = v}
        elseif target == "value" and v:match(re_match) then
            count = count + 1
            matches[count] = {key = k, value = v}
        end
    end
    
    -- 输出结果
    local target_name = (target == "key") and "键" or "值"
    print("对于" .. target_name .. "匹配正则表达式:" .. re_match)
    
    if count == 0 then
        print("---无结果---")
    else
        print("---" .. count .. "个结果---")
        print("| KEY            |  VALUE |")
        for _, match in ipairs(matches) do
            -- 处理KEY的显示长度
            local display_key = match.key
            if #display_key > 16 then
                display_key = display_key:sub(1, 16)
            else
                display_key = display_key .. string.rep(" ", 16 - #display_key)
            end
            
            print("| " .. display_key .. " |  " .. match.value .. " |")
        end
    end
    
    return true
end

-- 信息菜单
local function cvcli_info()
    -- 检查YML文件是否有效
    local yml_valid, data, yml_err = check_yml_valid()
    
    -- 输出标题
    print("[cvcli]")
    print("ver: " .. VERSION)
    print("env: " .. get_os_env())
    
    -- 如果YML文件检查不通过
    if not yml_valid then
        print("---YML ERR---")
        print("Input 'rebuild' to rebuild (WARN: all data will lost)>>>")
        
        local input = io.read()
        if input == "rebuild" then
            if rebuild_yml() then
                print("---REBUILD SUCCESS---")
                -- 重新检查
                yml_valid, data = check_yml_valid()
                if yml_valid then
                    -- 显示重建后的信息
                    print("key(s): 1")
                    print("lastkey: " .. data["---last---"])
                end
            else
                print("重建失败")
            end
        end
    else
        -- 计算键的数量（不包括---last---）
        local key_count = 0
        for k, _ in pairs(data) do
            if k ~= "---last---" then
                key_count = key_count + 1
            end
        end
        
        print("key(s): " .. key_count)
        print("lastkey: " .. data["---last---"])
    end
end

-- 合并或替换菜单
-- @param mode: 模式: combine或replace
-- @param file: 要操作的文件名
local function cvcli_combine_replace(mode, file)
    -- 检查参数
    if not mode or not file then
        cvcli_std_note("参数不能为空", true)
        return false
    end
    
    -- 检查模式是否合法
    if mode ~= "combine" and mode ~= "replace" then
        cvcli_std_note("模式必须是'combine'或'replace'", true)
        return false
    end
    
    -- 检查YML文件是否有效
    local yml_valid, current_data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ".运行`cvcli`指令重新构建", true)
        return false
    end
    
    -- 检查目标文件是否存在
    local target_file = io.open(file, "r")
    if not target_file then
        cvcli_std_note("目标文件不存在: " .. file, true)
        return false
    end
    
    -- 读取目标文件内容
    local target_data = {}
    local is_valid_yml = true
    local error_message = ""
    
    for line in target_file:lines() do
        local k, v = line:match("^%s*([^:]+)%s*:%s*(.+)%s*$")
        
        -- 检查格式是否正确
        if not k or not v then
            is_valid_yml = false
            error_message = "目标文件格式错误，不是标准的键值对格式"
            break
        end
        
        -- 检查键是否合法
        local valid, err_msg = is_valid_key(k)
        if not valid and k ~= "---last---" then
            is_valid_yml = false
            error_message = "目标文件中键 '" .. k .. "' " .. err_msg
            break
        end
        
        -- 检查是否存在重复键
        if target_data[k] then
            is_valid_yml = false
            error_message = "目标文件中存在重复的键: " .. k
            break
        end
        
        -- 记录键
        target_data[k] = v
    end
    
    target_file:close()
    
    -- 检查目标文件是否合法
    if not is_valid_yml then
        cvcli_std_note(error_message, true)
        return false
    end
    
    -- 处理replace模式
    if mode == "replace" then
        print("警告: 替换模式将覆盖所有现有数据")
        print("请输入'yes'三次以确认（输入其他内容取消）: ")
        
        for i = 1, 3 do
            io.write("确认 " .. i .. "/3: ")
            local confirm = io.read()
            if confirm ~= "yes" then
                print("操作已取消")
                return false
            end
        end
        
        -- 确保保留---last---键
        if not target_data["---last---"] then
            target_data["---last---"] = "default"
        end
        
        -- 写入文件
        local file = io.open(YML_FILENAME, "w")
        if file then
            for k, v in pairs(target_data) do
                file:write(k .. ": " .. tostring(v) .. "\n")
            end
            file:close()
            print("替换完成")
            return true
        else
            cvcli_std_note("在写入时出现错误.检查权限", true)
            return false
        end
    end
    
    -- 处理combine模式
    if mode == "combine" then
        -- 查找冲突键
        local conflicts = {}
        for k, v in pairs(target_data) do
            if current_data[k] and k ~= "---last---" then
                table.insert(conflicts, k)
            end
        end
        
        -- 处理冲突
        if #conflicts > 0 then
            print("发现" .. #conflicts .. "个冲突键:")
            for i, k in ipairs(conflicts) do
                print(i .. ". " .. k .. ": 当前值=" .. current_data[k] .. ", 新值=" .. target_data[k])
            end
            
            print("\n解决冲突:")
            for i, k in ipairs(conflicts) do
                io.write("键 '" .. k .. "': 保留当前值(1)或使用新值(2)? ")
                local choice = io.read()
                
                if choice == "2" then
                    current_data[k] = target_data[k]
                end
                
                -- 从target_data中移除已处理的冲突键
                target_data[k] = nil
            end
        end
        
        -- 合并非冲突键
        for k, v in pairs(target_data) do
            if k ~= "---last---" then
                current_data[k] = v
            end
        end
        
        -- 写入文件
        local file = io.open(YML_FILENAME, "w")
        if file then
            for k, v in pairs(current_data) do
                file:write(k .. ": " .. tostring(v) .. "\n")
            end
            file:close()
            print("合并完成")
            return true
        else
            cvcli_std_note("在写入时出现错误.检查权限", true)
            return false
        end
    end
end

-- ============== 命令行解析和主函数 ==============

-- 解析并执行指令
-- @param args: 命令行参数表
local function execute_command(args)
    -- 没有参数，显示信息菜单
    if #args == 0 then
        cvcli_info()
        return true
    end
    
    -- 处理命令
    local cmd = args[1]
    
    -- 读取上次使用的键: cvcli -l
    if cmd == "-l" then
        return cvcli_read_last()
    end
    
    -- 写入键值对: cvcli -w key value
    if cmd == "-w" then
        if #args < 3 then
            cvcli_std_note("写入命令需要指定键和值", true)
            return false
        end
        return cvcli_write(args[2], args[3])
    end
    
    -- 写入剪贴板中的值: cvcli -wv key
    if cmd == "-wv" then
        if #args < 2 then
            cvcli_std_note("写入剪贴板命令需要指定键", true)
            return false
        end
        
        local clipboard_text = get_clipboard()
        if not clipboard_text then
            cvcli_std_note("无法获取剪贴板内容", true)
            return false
        end
        
        return cvcli_write(args[2], clipboard_text)
    end
    
    -- 只向已存在的键写入值: cvcli -wr key value
    if cmd == "-wr" then
        if #args < 3 then
            cvcli_std_note("写入命令需要指定键和值", true)
            return false
        end
        return cvcli_write(args[2], args[3], true)
    end
    
    -- 合并文件: cvcli -cc filename
    if cmd == "-cc" then
        if #args < 2 then
            cvcli_std_note("合并命令需要指定文件名", true)
            return false
        end
        return cvcli_combine_replace("combine", args[2])
    end
    
    -- 替换文件: cvcli -cr filename
    if cmd == "-cr" then
        if #args < 2 then
            cvcli_std_note("替换命令需要指定文件名", true)
            return false
        end
        return cvcli_combine_replace("replace", args[2])
    end
    
    -- 正则匹配显示: cvcli -mk pattern (匹配键)
    if cmd == "-mk" then
        if #args < 2 then
            cvcli_std_note("匹配命令需要指定正则表达式", true)
            return false
        end
        return cvcli_match_show("key", args[2])
    end
    
    -- 正则匹配显示: cvcli -mv pattern (匹配值)
    if cmd == "-mv" then
        if #args < 2 then
            cvcli_std_note("匹配命令需要指定正则表达式", true)
            return false
        end
        return cvcli_match_show("value", args[2])
    end
    
    -- 如果不是以上命令，则认为是读取键: cvcli key
    return cvcli_read(cmd)
end

-- 主函数
local function main()
    -- 获取命令行参数
    local args = {}
    for i = 1, #arg do
        args[i] = arg[i]
    end
    
    -- 执行命令
    local status, result = pcall(execute_command, args)
    
    -- 处理错误
    if not status then
        print(result)
        os.exit(1)
    end
    
    os.exit(result and 0 or 1)
end

-- 执行主函数
main()