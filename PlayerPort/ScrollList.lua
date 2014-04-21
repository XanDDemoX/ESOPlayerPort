---------------------------------------------
--[[		   ScrollList		 		 ]]--
--[[ A scrolling button listview control ]]--
--[[			   		 				 ]]--
--[[	Version 0.1.1	  	 	 		 ]]--
---------------------------------------------
function ScrollList(name,title,width,height,anchorTop)

	local wnd = WINDOW_MANAGER:CreateTopLevelWindow(name)
	
	if anchorTop ~= nil then 
		wnd:SetAnchor(TOP,anchorTop,BOTTOM,0,0)
	end
	
	wnd:SetWidth(width)
	wnd:SetHeight(height)
	wnd:SetMouseEnabled(true)
	
	local bg = wnd:CreateControl(name.."_Background",CT_BACKDROP)
	
	bg:SetAnchorFill(wnd)
	bg:SetCenterColor(0,0,0,0.8)
	bg:SetEdgeColor(0,0,0,0.8)
	
	local lbl = wnd:CreateControl(name.."_Title",CT_LABEL)

	lbl:SetDimensions(wnd:GetWidth(), 26)
	lbl:SetAnchor(TOPLEFT,wnd,TOPLEFT,10,10)
	lbl:SetFont("ZoFontWinH4")
	lbl:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
	lbl:SetText(title)
	
	local scroll = wnd:CreateControl(name.."_Scroll",CT_SCROLL)

	scroll:SetAnchor(TOPLEFT,lbl,BOTTOMLEFT,0,0)
	scroll:SetAnchor(BOTTOMRIGHT,wnd,BOTTOMRIGHT,0,-5)
	scroll:SetScrollBounding(SCROLL_BOUNDING_DEFAULT)
	
	local slider = wnd:CreateControl(name.."_Slider",CT_SLIDER)
	local tex = "/esoui/art/miscellaneous/scrollbox_elevator.dds"
	slider:SetWidth(20)
	slider:SetAnchor(TOPLEFT,scroll,TOPRIGHT,-slider:GetWidth(),0)
	slider:SetAnchor(BOTTOMLEFT,scroll,BOTTOMRIGHT,-slider:GetWidth(),0)
	slider:SetOrientation(ORIENTATION_VERTICAL)
	

    slider:SetThumbTexture(tex, tex, tex, 20, 20, 0, 0, 1, 1)

    slider:SetValue(0)
    slider:SetValueStep(1)

	slider:SetMouseEnabled(true)
	
	local scrollwnd = scroll:CreateControl(name.."_Scroll_Content",CT_CONTROL)
	scrollwnd:SetAnchor(TOPLEFT,scroll,TOPLEFT,0,0)
	scrollwnd:SetWidth(width)
	scrollwnd:SetParent(scroll)
	scrollwnd:SetMouseEnabled(true)
	
	scrollwnd:SetHandler("OnMouseWheel",function(self, delta)
		local newval = math.min(math.max(0,slider:GetValue()-delta),math.max(scroll:GetHeight()-slider:GetHeight(),slider:GetHeight()))
		slider:SetValue(newval)
    end)
	slider:SetHandler("OnValueChanged", function(self, val, eventReason) 
		scrollwnd:SetAnchor(TOPLEFT,scroll,TOPLEFT,0,-val)
	end)
	
	wnd.bg = bg
	wnd.lbl = lbl
	wnd.scroll = scrollwnd
	wnd.scroll.slider = slider
	
	local _buttons = {}
	
	local lastbtn
	wnd.AddButton = function(self,id,text,height,onclick)
		if _buttons[id] ~= nil then 
			
			return
		end
		
		local btn = scrollwnd:CreateControl(id,CT_BUTTON)
		if lastbtn == nil then 
			btn:SetAnchor(TOPLEFT)
		else
			btn:SetAnchor(TOPLEFT,lastbtn,BOTTOMLEFT,0,0)
		end
		
		btn:SetWidth(width-slider:GetWidth())
		btn:SetHeight(height or 30)
		btn:SetFont("ZoFontWinH4")
		btn:SetText(text or "nil")
		btn:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
		
		if onclick ~= nil then 
			btn:SetHandler("OnClicked",onclick)
			btn:SetMouseOverFontColor(1.0,0,0,1.0)
		end
		
		scrollwnd:SetHeight(scrollwnd:GetHeight() + btn:GetHeight())

		slider:SetMinMax(0,math.max(scroll:GetHeight()-slider:GetHeight(),slider:GetHeight()))
		
		lastbtn = btn
		_buttons[id] = btn
		table.insert(_buttons,btn)
		return btn
	end
	
	wnd.HideAll = function(self,startIndex)
		local count = #_buttons
		
		if startIndex > 0 and startIndex <= count then
			for i = startIndex, count do
				_buttons[i]:SetHidden(true)
			end
		end
	end
	
	wnd.SetScrollHeightForVisible = function(self)
		local count = #_buttons
		local height = 0
		
		for i = 1, count do
			if _buttons[i]:IsHidden() == false then
				height = height + _buttons[i]:GetHeight()
			end
		end
		scrollwnd:SetHeight(height)
	end
	
	wnd.GetButtonCount = function(self)
		return #_buttons
	end
	
	wnd.GetButton = function(self,id)
		return _buttons[id]
	end
	
	wnd.GetButtons = function(self)
		local i = 0
		local count = #_buttons
		
		return function()
			if i < count then 
				i = i + 1 
				return i,_buttons[i]
			end
		end
	end
	
	return wnd
end
