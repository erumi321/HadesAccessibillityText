textboxToId = {}
SaveIgnores["textboxToId"] = true
ModUtil.WrapBaseFunction("CreateTextBoxWithFormat", function(baseFunc, args, ...)
	if args.Text == nil then
		args.Text = ""
	end
	local newTextbox = DeepCopyTable(args)

	newTextbox = GenerateNewTextbox(newTextbox)

	--Store it for ModifyTextbox
	if args.Id ~= nil then
		--Store it for ModifyTextbox
		if textboxToId[args.Id] == nil then
			textboxToId[args.Id] = {}
		end
		textboxToId[args.Id] = newTextbox
		textboxToId[args.Id].Id = args.Id
	end

	return baseFunc(newTextbox)
end)
ModUtil.WrapBaseFunction("CreateTextBox", function (baseFunc, args, ...)
		if args.Text == nil then
			args.Text = ""
		end
		local newTextbox = DeepCopyTable(args)
	
		if args.RawText == nil then
			newTextbox = GenerateNewTextbox(newTextbox)
		end
	
		if args.Id ~= nil then
			--Store it for ModifyTextbox
			if textboxToId[args.Id] == nil then
				textboxToId[args.Id] = {}
			end
			textboxToId[args.Id] = newTextbox
			textboxToId[args.Id].Id = args.Id
		end

		return baseFunc(newTextbox)
end)

ModUtil.WrapBaseFunction("DestroyTextBox", function (baseFunc, args, ...)
	if args.Id ~= nil then
		if textboxToId[args.Id] ~= nil then
			textboxToId[args.Id] = nil
		end
	elseif args.Ids ~= nil then
		for k,v in pairs(args.Ids) do
			textboxToId[v] = nil
		end
	end
	return baseFunc(args)
end)

local cooldown = 0.0000000005
ModUtil.WrapBaseFunction("ModifyTextBox", function (baseFunc, args, ...)
	if args.Text == nil then
		-- local color = Color.Yellow
		-- if args.Color ~= nil then
		-- 	color[4] = args.Color[4] or 255
		-- end
		-- args.Color = color
		args.Font = "AlegreyaSansSCRegular"
		args.ShadowColor = {0,0,0,0}
		return baseFunc(args)
	end

	local newTextbox = DeepCopyTable(textboxToId[args.Id])

	if newTextbox == nil then
		return
	end

	--Override with new values
	for k,v in pairs(args) do
		newTextbox[k] = v
	end

	--create a new textbox
	newTextbox = GenerateNewTextbox(newTextbox)
	newTextbox.Id = args.Id
	DestroyTextBox({Id = args.Id})
	CreateTextBox(newTextbox)
	textboxToId[args.Id] = newTextbox
end)
function GenerateNewTextbox(newBox)
	--If in the mirror gonly change the Number text as the other text doesn't work for some reason
	if IsScreenOpen("MetaUpgrade") then
		local newText = ""
		local newTextbox = DeepCopyTable(newBox)
		if newBox.LuaKey ~= nil then
			if newBox.LuaValue.Amount ~= nil or newBox.LuaValue.CurrentAmount ~= nil then
				for k,v in pairs(TextBoxToRawTextBox(newTextbox, {AllowControllIcons = true, RemoveIcons = true, RemoveIconExemptions = {"LockKeySmall"}, IgnoreFormats = true})) do
					local appendText = v.RawText or ""
					if appendText == "" then
						if string.find(newTextbox.Text, "_On") then
							appendText = "Checked"
						else
							appendText = "UnChecked"
						end
					else
					--The actual value is stored in the Amount LuaValue, if I do it just on text then for somereason it will "hang" on values so when you swap its still
					--the same numeric value as the last element you swapped to
						if v.LuaValue ~= nil and v.LuaValue.Amount ~= nil then
							local addPercent = false
							local addKeys = appendText:find("Key")
							if string.find( appendText,"%%") then
								addPercent = true	
							end
							local splitVal = RawTextSplit(appendText, " ", true)
							appendText = tostring(v.LuaValue.Amount)
							if addKeys then
								appendText = appendText .. " Key"
							end
							if addPercent then
								appendText = appendText .. "%"
							end
						end
					end
					newText = newText .. appendText
				end

				newTextbox.Text = nil
				newTextbox.RawText = newText
			end
		end
		--Transparent text will stay at the same level of transparency
		local color = Color.Yellow
		if newBox.Color ~= nil then
			color[4] = newBox.Color[4] or 255
		end
		newTextbox.Color = color
		newTextbox.Font = "AlegreyaSansSCRegular"
		newTextbox.ShadowColor = {0,0,0,0}
		-- DebugPrintTable("color", color)

		return newTextbox
	end
	local newTextbox = newBox
	local newText = ""
	--If it is a god interact it will be generic text but the acutal value will be in the LuaValue
	if newTextbox.Text == "NPCInteractText" then
		newTextbox.Text = newTextbox.LuaValue.BaseUseText
	end

	for k,v in pairs(TextBoxToRawTextBox(newTextbox, {AllowControllIcons = true, IgnoreFormats = true, AllowSpecificIcons = {"Slash"}})) do
		newText = newText .. (v.RawText or "")
	end
	--Remove column formatting from newText
	if string.find(newText, "\\Column ") then
		local startText = newText:sub(1, string.find(newText, "\\Column "))
		local endText = newText:sub(string.find(newText, "\\Column "), #newText)
		endText = endText:sub(9)
		endText = endText:sub(#RawTextSplit(endText, " ", false)[1] + 1)
		newText = startText .. endText
	end

	--Swap Text and RawText
	newTextbox.Text = nil
	newTextbox.RawText = newText
	--Transparent text will stay at the same level of transparency
	local color = Color.Yellow
	if newBox.Color ~= nil then
		color[4] = newBox.Color[4] or 255
	end
	-- DebugPrintTable("color", color)
	newTextbox.Color = color
	newTextbox.Font = "AlegreyaSansSCRegular"
	newTextbox.ShadowColor = {0,0,0,0}

	return newTextbox
end

function DebugPrintTable(tableName, table, depth)
    if table == nil then
        DebugPrint({Text = tableName .. " is nil"})
        return
    end
    if depth == nil then
        depth = 0
    end
    local whiteSpaceBegin = "";
    local newDepth = depth
    if depth == -1  then 
        newDepth = -1
    else
        for i = 1, depth do
            for x = 1,2 do
                whiteSpaceBegin = whiteSpaceBegin .. " "
            end
        end
        newDepth = depth + 1
    end
    DebugPrint({Text = whiteSpaceBegin:sub(0,(depth-1) * 2) .. (tostring(tableName) or "Table") .. " ={"})
    for k,v in pairs(table)do
        if type(v) == "table" then
            DebugPrintTable(tostring(k), v, newDepth)
        else
            DebugPrint({Text = whiteSpaceBegin .. tostring(k) .. "=" .. tostring(v)})
        end
    end
    DebugPrint({Text = whiteSpaceBegin:sub(0,((depth-1) * 2) + 1) .. "}"})
end