--[[
cvcli project source code

Author: WaterRun
Date: 2025-03-10
File: cvcli.lua
]]

-- Global constants
YML_FILENAME = 'cvcli.yml'
VERSION = 0.1

-- ============== Utility functions ==============

-- Standardized prompt messages  
-- @param info: Message content
-- @oaram is_err: Whether it's an error, boolean or nil (empty)
local function cvcli_std_note(info, is_err)
    if is_err then
        error(">>> ERR:" .. info .. " <<<")
    else
        print("---" .. info .. "---")
    end
end

-- Get current operating system information
-- @return: Operating system type string
local function get_os_env()
    return "win" -- Only support windows for now
end

-- Operating system related clipboard operations
-- Write text to clipboard
-- @param text: Text to be written to clipboard
-- @return: Whether successful, boolean
local function set_clipboard(text)
    local success = false
    
    -- Windows clipboard operation
    local tempfile = os.tmpname()
    local file = io.open(tempfile, "w")
    if file then
        file:write(text)
        file:close()
        
        -- Use powershell command to write file content to clipboard
        local cmd = 'powershell -command "Get-Content \'' .. tempfile .. '\' | Set-Clipboard"'
        local result = os.execute(cmd)
        os.remove(tempfile)
        success = (result == 0 or result == true)
    end
    
    return success
end

-- Read text from clipboard
-- @return: Clipboard content, string or nil
local function get_clipboard()
    local text = nil
    
    -- Windows clipboard operation
    local tempfile = os.tmpname()
    -- Use powershell command to read clipboard content to file
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

-- ============== YML file operations ==============

-- Check if key is valid
-- @param key: Key to check
-- @return: Whether valid, boolean and error message
local function is_valid_key(key)
    -- Check if empty
    if not key or key == "" then
        return false, "Key cannot be empty"
    end
    
    -- Check length
    if #key > 16 then
        return false, "Key cannot exceed 16 characters"
    end
    
    -- Check if starts with three consecutive '-'
    if key:match("^%-%-%-") and key ~= "---last---" then
        return false, "Key cannot start with three consecutive '-' (this is reserved for cvcli)"
    end
    
    -- Check if contains special characters (spaces, etc.)
    if key:match("%s") then
        return false, "Key cannot contain spaces"
    end
    
    -- Check if it's a reserved word
    local reserved_keys = {
        "-w", "-wv", "-wl", "-wvl", "-wr", "-wvlr", "-l", "-mk", "-mv", "-cc", "-cr"
    }
    
    for _, reserved in ipairs(reserved_keys) do
        if key == reserved then
            return false, "Key cannot be a reserved word: " .. reserved
        end
    end
    
    return true, nil
end

-- Check if YML file is valid
-- @return: Whether valid, data table, error message
local function check_yml_valid()
    -- Check if file exists and is readable
    local file = io.open(YML_FILENAME, "r")
    if not file then
        -- Try to create the file and add default content
        local create_file = io.open(YML_FILENAME, "w")
        if not create_file then
            return false, nil, "YML file does not exist and cannot be created. Check permissions"
        end
        create_file:write("---last---: default\n")
        create_file:close()
        
        file = io.open(YML_FILENAME, "r")
        if not file then
            return false, nil, "YML file still cannot be read after creation. Check permissions"
        end
    end
    
    -- Read file content
    local content = file:read("*all")
    file:close()
    
    -- Parse YAML content
    local data = {}
    local keys = {}
    local has_last_key = false
    
    for line in content:gmatch("[^\r\n]+") do
        local k, v = line:match("^%s*([^:]+)%s*:%s*(.+)%s*$")
        
        -- Check if format is correct
        if not k or not v then
            return false, nil, "YML file format error, not standard key-value pair format"
        end
        
        -- Check if key is valid
        local valid, err_msg = is_valid_key(k)
        if not valid and k ~= "---last---" then
            return false, nil, "Key '" .. k .. "' " .. err_msg
        end
        
        -- Check for duplicate keys
        if keys[k] then
            return false, nil, "Duplicate key exists in YML file: " .. k
        end
        
        -- Record key
        keys[k] = true
        data[k] = v
        
        -- Check if it contains ---last--- key
        if k == "---last---" then
            has_last_key = true
        end
    end
    
    -- Check if it contains ---last--- key
    if not has_last_key then
        return false, data, "YML file is missing required ---last--- key"
    end
    
    -- Check if file is writable
    file = io.open(YML_FILENAME, "a")
    if not file then
        return false, data, "YML file is not writable. Check permissions"
    end
    file:close()
    
    return true, data, nil
end

-- Ensure YML file is valid, try to fix if not
-- @return: Whether valid, data table, error message
local function ensure_yml_valid()
    local valid, data, err_msg = check_yml_valid()
    
    if not valid then
        -- If data already exists, try to fix the file
        if data then
            -- Ensure ---last--- key exists
            data["---last---"] = "default"
            
            -- Write back to file
            local file = io.open(YML_FILENAME, "w")
            if file then
                for k, v in pairs(data) do
                    -- Check key validity again
                    local key_valid, _ = is_valid_key(k)
                    if key_valid or k == "---last---" then
                        file:write(k .. ": " .. tostring(v) .. "\n")
                    end
                end
                file:close()
                
                -- Check again
                return check_yml_valid()
            else
                return false, nil, "Cannot fix YML file. Check permissions"
            end
        else
            -- Try to create new file
            local file = io.open(YML_FILENAME, "w")
            if file then
                file:write("---last---: default\n")
                file:close()
                
                -- Check again
                return check_yml_valid()
            else
                return false, nil, "Cannot create YML file. Check permissions"
            end
        end
    end
    
    return valid, data, err_msg
end

-- Rebuild YML file
-- @return: Whether successful
local function rebuild_yml()
    local file = io.open(YML_FILENAME, "w")
    if not file then
        cvcli_std_note("Cannot create YML file. Check permissions", true)
        return false
    end
    
    file:write("---last---: default\n")
    file:close()
    return true
end

-- ============== Core functionality functions ==============

-- Write key-value pair  
-- @param key: Key to write
-- @param value: Value to write  
-- @param readonly: Whether in read-only mode (cannot create new keys), boolean or nil (empty)
local function cvcli_write(key, value, readonly)
    -- Check if key is valid
    local valid, err_msg = is_valid_key(key)
    if not valid then
        cvcli_std_note(err_msg, true)
        return false
    end
    
    -- Check if YML file is valid
    local yml_valid, data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ". Run `cvcli` command to rebuild", true)
        return false
    end
    
    -- Check read-only mode
    if readonly and data[key] == nil then
        cvcli_std_note("Read-only mode restricts creating new keys", true)
        return false
    end
    
    -- Update data
    data[key] = value
    
    -- If not ---last--- key, update ---last--- to current key
    if key ~= "---last---" then
        data["---last---"] = key
    end
    
    -- Write back to file
    local file = io.open(YML_FILENAME, "w")
    if file then
        for k, v in pairs(data) do
            file:write(k .. ": " .. tostring(v) .. "\n")
        end
        file:close()
        print("Value written for key '" .. key .. "'")
        return true
    else
        cvcli_std_note("Error occurred during write. Check permissions", true)
        return false
    end
end

-- Read key-value pair  
-- @param key: Key to read
-- @return: Value read, nil if key doesn't exist
local function cvcli_read(key)
    -- Check parameters
    if not key then
        cvcli_std_note("Key cannot be empty", true)
        return nil
    end
    
    -- Check if YML file is valid
    local yml_valid, data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ". Run `cvcli` command to rebuild", true)
        return nil
    end
    
    -- Get value directly from data
    if data[key] then
        -- If not ---last--- key, update ---last--- to current key
        if key ~= "---last---" then
            -- Write back to file to update ---last---
            data["---last---"] = key
            local file = io.open(YML_FILENAME, "w")
            if file then
                for k, v in pairs(data) do
                    file:write(k .. ": " .. tostring(v) .. "\n")
                end
                file:close()
            end
        end
        
        -- Copy the read value to clipboard
        local value = data[key]
        if set_clipboard(value) then
            print("Value for key '" .. key .. "' has been read and copied to clipboard: " .. value)
        else
            print("Value for key '" .. key .. "' has been read: " .. value)
            cvcli_std_note("Failed to copy to clipboard", true)
        end
        
        return value
    else
        cvcli_std_note("Specified key does not exist", true)
        return nil
    end
end

-- Read last used key
-- @return: Value of last used key, nil if it doesn't exist
local function cvcli_read_last()
    -- Check if YML file is valid
    local yml_valid, data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ". Run `cvcli` command to rebuild", true)
        return nil
    end
    
    -- Get last used key
    local last_key = data["---last---"]
    if last_key == "default" or not data[last_key] then
        cvcli_std_note("No valid last usage record", true)
        return nil
    end
    
    -- Read value of last used key
    local value = data[last_key]
    
    -- Copy the read value to clipboard
    if set_clipboard(value) then
        print("Value of last used key '" .. last_key .. "' has been read and copied to clipboard: " .. value)
    else
        print("Value of last used key '" .. last_key .. "' has been read: " .. value)
        cvcli_std_note("Failed to copy to clipboard", true)
    end
    
    return value
end

-- Delete key-value pair
-- @param key: Key to delete
-- @return: Whether operation successful, boolean
local function cvcli_remove(key)
    -- Check parameters
    if not key then
        cvcli_std_note("Key cannot be empty", true)
        return false
    end
    
    -- Not allowed to delete ---last--- key
    if key == "---last---" then
        cvcli_std_note("Cannot delete system reserved key ---last---", true)
        return false
    end
    
    -- Check if YML file is valid
    local yml_valid, data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ". Run `cvcli` command to rebuild", true)
        return false
    end
    
    -- Check if key exists
    if not data[key] then
        cvcli_std_note("Specified key does not exist", true)
        return false
    end
    
    -- Delete key
    data[key] = nil
    
    -- If deleted key is recorded by last key, reset last key
    if data["---last---"] == key then
        data["---last---"] = "default"
    end
    
    -- Write back to file
    local file = io.open(YML_FILENAME, "w")
    if file then
        for k, v in pairs(data) do
            file:write(k .. ": " .. tostring(v) .. "\n")
        end
        file:close()
        print("Key '" .. key .. "' has been deleted")
        return true
    else
        cvcli_std_note("Error occurred during write. Check permissions", true)
        return false
    end
end

-- Regular expression match and formatted output
-- @param target: Match target: key or value
-- @param re_match: Regular expression to match
local function cvcli_match_show(target, re_match)
    -- Check parameters
    if not target or not re_match then
        cvcli_std_note("Parameters cannot be empty", true)
        return false
    end
    
    -- Ensure target is key or value
    if target ~= "key" and target ~= "value" then
        cvcli_std_note("Match target must be 'key' or 'value'", true)
        return false
    end
    
    -- Check if YML file is valid
    local yml_valid, data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ". Run `cvcli` command to rebuild", true)
        return false
    end
    
    -- Store match results
    local matches = {}
    local count = 0
    
    -- Search for matches
    for k, v in pairs(data) do
        if target == "key" and k:match(re_match) then
            count = count + 1
            matches[count] = {key = k, value = v}
        elseif target == "value" and v:match(re_match) then
            count = count + 1
            matches[count] = {key = k, value = v}
        end
    end
    
    -- Output results
    local target_name = (target == "key") and "key" or "value"
    print("For " .. target_name .. " matching regex:" .. re_match)
    
    if count == 0 then
        print("---No results---")
    else
        print("---" .. count .. " results---")
        print("| KEY            |  VALUE |")
        for _, match in ipairs(matches) do
            -- Handle KEY display length
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

-- Information menu
local function cvcli_info()
    -- Check if YML file is valid
    local yml_valid, data, yml_err = check_yml_valid()
    
    -- Output title
    print("[cvcli]")
    print("ver: " .. VERSION)
    print("env: " .. get_os_env())
    
    -- If YML file check fails
    if not yml_valid then
        print("---YML ERR---")
        print("Input 'rebuild' to rebuild (WARN: all data will lost)>>>")
        
        local input = io.read()
        if input == "rebuild" then
            if rebuild_yml() then
                print("---REBUILD SUCCESS---")
                -- Check again
                yml_valid, data = check_yml_valid()
                if yml_valid then
                    -- Display rebuilt information
                    print("key(s): 1")
                    print("lastkey: " .. data["---last---"])
                end
            else
                print("Rebuild failed")
            end
        end
    else
        -- Count number of keys (excluding ---last---)
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

-- Combine or replace menu
-- @param mode: Mode: combine or replace
-- @param file: Filename to operate on
local function cvcli_combine_replace(mode, file)
    -- Check parameters
    if not mode or not file then
        cvcli_std_note("Parameters cannot be empty", true)
        return false
    end
    
    -- Check if mode is valid
    if mode ~= "combine" and mode ~= "replace" then
        cvcli_std_note("Mode must be 'combine' or 'replace'", true)
        return false
    end
    
    -- Check if YML file is valid
    local yml_valid, current_data, yml_err = ensure_yml_valid()
    if not yml_valid then
        cvcli_std_note(yml_err .. ". Run `cvcli` command to rebuild", true)
        return false
    end
    
    -- Check if target file exists
    local target_file = io.open(file, "r")
    if not target_file then
        cvcli_std_note("Target file does not exist: " .. file, true)
        return false
    end
    
    -- Read target file content
    local target_data = {}
    local is_valid_yml = true
    local error_message = ""
    
    for line in target_file:lines() do
        local k, v = line:match("^%s*([^:]+)%s*:%s*(.+)%s*$")
        
        -- Check if format is correct
        if not k or not v then
            is_valid_yml = false
            error_message = "Target file format error, not standard key-value pair format"
            break
        end
        
        -- Check if key is valid
        local valid, err_msg = is_valid_key(k)
        if not valid and k ~= "---last---" then
            is_valid_yml = false
            error_message = "Key '" .. k .. "' in target file " .. err_msg
            break
        end
        
        -- Check for duplicate keys
        if target_data[k] then
            is_valid_yml = false
            error_message = "Duplicate key exists in target file: " .. k
            break
        end
        
        -- Record key
        target_data[k] = v
    end
    
    target_file:close()
    
    -- Check if target file is valid
    if not is_valid_yml then
        cvcli_std_note(error_message, true)
        return false
    end
    
    -- Handle replace mode
    if mode == "replace" then
        print("Warning: Replace mode will overwrite all existing data")
        print("Please type 'yes' three times to confirm (type anything else to cancel): ")
        
        for i = 1, 3 do
            io.write("Confirm " .. i .. "/3: ")
            local confirm = io.read()
            if confirm ~= "yes" then
                print("Operation canceled")
                return false
            end
        end
        
        -- Ensure ---last--- key is preserved
        if not target_data["---last---"] then
            target_data["---last---"] = "default"
        end
        
        -- Write to file
        local file = io.open(YML_FILENAME, "w")
        if file then
            for k, v in pairs(target_data) do
                file:write(k .. ": " .. tostring(v) .. "\n")
            end
            file:close()
            print("Replace completed")
            return true
        else
            cvcli_std_note("Error occurred during write. Check permissions", true)
            return false
        end
    end
    
    -- Handle combine mode
    if mode == "combine" then
        -- Find conflicting keys
        local conflicts = {}
        for k, v in pairs(target_data) do
            if current_data[k] and k ~= "---last---" then
                table.insert(conflicts, k)
            end
        end
        
        -- Handle conflicts
        if #conflicts > 0 then
            print("Found " .. #conflicts .. " conflicting keys:")
            for i, k in ipairs(conflicts) do
                print(i .. ". " .. k .. ": current value=" .. current_data[k] .. ", new value=" .. target_data[k])
            end
            
            print("\nResolve conflicts:")
            for i, k in ipairs(conflicts) do
                io.write("Key '" .. k .. "': keep current value(1) or use new value(2)? ")
                local choice = io.read()
                
                if choice == "2" then
                    current_data[k] = target_data[k]
                end
                
                -- Remove processed conflict key from target_data
                target_data[k] = nil
            end
        end
        
        -- Merge non-conflicting keys
        for k, v in pairs(target_data) do
            if k ~= "---last---" then
                current_data[k] = v
            end
        end
        
        -- Write to file
        local file = io.open(YML_FILENAME, "w")
        if file then
            for k, v in pairs(current_data) do
                file:write(k .. ": " .. tostring(v) .. "\n")
            end
            file:close()
            print("Combine completed")
            return true
        else
            cvcli_std_note("Error occurred during write. Check permissions", true)
            return false
        end
    end
end

-- ============== Command line parsing and main function ==============

-- Parse and execute command
-- @param args: Command line argument table
local function execute_command(args)
    -- No arguments, display information menu
    if #args == 0 then
        cvcli_info()
        return true
    end
    
    -- Process command
    local cmd = args[1]
    
    -- Read last used key: cvcli -l
    if cmd == "-l" then
        return cvcli_read_last()
    end
    
    -- Write key-value pair: cvcli -w key value
    if cmd == "-w" then
        if #args < 3 then
            cvcli_std_note("Write command requires key and value", true)
            return false
        end
        return cvcli_write(args[2], args[3])
    end
    
    -- Write clipboard value: cvcli -wv key
    if cmd == "-wv" then
        if #args < 2 then
            cvcli_std_note("Write clipboard command requires key", true)
            return false
        end
        
        local clipboard_text = get_clipboard()
        if not clipboard_text then
            cvcli_std_note("Cannot get clipboard content", true)
            return false
        end
        
        return cvcli_write(args[2], clipboard_text)
    end
    
    -- Write to existing key only: cvcli -wr key value
    if cmd == "-wr" then
        if #args < 3 then
            cvcli_std_note("Write command requires key and value", true)
            return false
        end
        return cvcli_write(args[2], args[3], true)
    end
    
    -- Combine file: cvcli -cc filename
    if cmd == "-cc" then
        if #args < 2 then
            cvcli_std_note("Combine command requires filename", true)
            return false
        end
        return cvcli_combine_replace("combine", args[2])
    end
    
    -- Replace file: cvcli -cr filename
    if cmd == "-cr" then
        if #args < 2 then
            cvcli_std_note("Replace command requires filename", true)
            return false
        end
        return cvcli_combine_replace("replace", args[2])
    end
    
    -- Regular expression match display: cvcli -mk pattern (match keys)
    if cmd == "-mk" then
        if #args < 2 then
            cvcli_std_note("Match command requires regular expression", true)
            return false
        end
        return cvcli_match_show("key", args[2])
    end
    
    -- Regular expression match display: cvcli -mv pattern (match values)
    if cmd == "-mv" then
        if #args < 2 then
            cvcli_std_note("Match command requires regular expression", true)
            return false
        end
        return cvcli_match_show("value", args[2])
    end
    
    -- If not any of the above commands, assume it's reading a key: cvcli key
    return cvcli_read(cmd)
end

-- Main function
local function main()
    -- Get command line arguments
    local args = {}
    for i = 1, #arg do
        args[i] = arg[i]
    end
    
    -- Execute command
    local status, result = pcall(execute_command, args)
    
    -- Handle errors
    if not status then
        print(result)
        os.exit(1)
    end
    
    os.exit(result and 0 or 1)
end

-- Execute main function
main()