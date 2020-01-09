local UI={}
local shaderUI={}
local textureUI={}
local imagesUI={}
local shaders={}
local screenx,screeny=guiGetScreenSize()
local currentShader
local prevTexture
local previewing
local dummyShader

function createUI()
	UI.window=guiCreateWindow(screenx*0.5-200,screeny*0.5-200,400,600,"Shaders",false)
	UI.list=guiCreateGridList(25,25,200,550,false,UI.window)
	guiGridListAddColumn(UI.list,"ID",0.2)
	guiGridListAddColumn(UI.list,"Shader",0.7)
	UI.newShader=guiCreateButton(250,25,200,30,"New shader",false,UI.window)
	UI.editShader=guiCreateButton(250,60,200,30,"Edit shader",false,UI.window)
	UI.deleteShader=guiCreateButton(250,95,200,30,"Delete shader",false,UI.window)
	
	UI.saveShader=guiCreateButton(250,140,200,30,"Save",false,UI.window)
	UI.loadShader=guiCreateButton(250,175,200,30,"Load",false,UI.window)
	UI.generateLua=guiCreateButton(250,210,200,30,"Generate lua",false,UI.window)
	UI.generateLuaLoop=guiCreateButton(250,245,200,30,"Generate lua (loop)",false,UI.window)
	UI.togglePreview=guiCreateButton(250,290,200,30,"(toggle) Preview",false,UI.window)
	
	UI.close=guiCreateButton(250,545,200,30,"Close",false,UI.window)
	guiSetVisible(UI.window,false)
	
	UI.saveWindow=guiCreateWindow(screenx*0.5-175,screeny*0.5-200,350,400,"save",false)
	UI.saveMemo=guiCreateMemo(25,25,300,300,"",false,UI.saveWindow)
	UI.closeSave=guiCreateButton(225,350,100,30,"Close",false,UI.saveWindow)
	guiSetVisible(UI.saveWindow,false)
	
	UI.loadWindow=guiCreateWindow(screenx*0.5-175,screeny*0.5-200,350,400,"save",false)
	UI.loadMemo=guiCreateMemo(25,25,300,300,"",false,UI.loadWindow)
	UI.closeLoad=guiCreateButton(25,350,100,30,"Close",false,UI.loadWindow)
	UI.loadLoad=guiCreateButton(225,350,100,30,"Load",false,UI.loadWindow)
	guiSetVisible(UI.loadWindow,false)
	
	addEventHandler("onClientGUIClick",UI.newShader,function()
		guiSetVisible(UI.window,false)
		if shaderUI.newWindow==nil then
			createShaderUI()
		end
		guiSetVisible(shaderUI.newWindow,true)
	end,false)
	
	addEventHandler("onClientGUIClick",UI.editShader,function()
		local row=guiGridListGetSelectedItem(UI.list)
		if row==-1 then return end
		local id=guiGridListGetItemText(UI.list,row,1)
		currentShader=shaders[tonumber(id)]
		guiSetText(shaderUI.nameLabel,currentShader.name)
		guiSetVisible(UI.window,false)
		guiSetVisible(shaderUI.editWindow,true)
		guiGridListClear(shaderUI.targets)
		for _,texture in pairs(currentShader.textures) do
			local row=guiGridListAddRow(shaderUI.targets)
			guiGridListSetItemText(shaderUI.targets,row,1,texture,false,false)
		end
	end,false)
	
	addEventHandler("onClientGUIClick",UI.deleteShader,function()
		local row=guiGridListGetSelectedItem(UI.list)
		if row==-1 then return end
		local id=guiGridListGetItemText(UI.list,row,1)
		shaders[tonumber(id)].removed=true
		guiGridListRemoveRow(UI.list,row)
		
	end,false)
	
	addEventHandler("onClientGUIClick",UI.saveShader,function()
		local row=guiGridListGetSelectedItem(UI.list)
		if row==-1 then return end
		local id=guiGridListGetItemText(UI.list,row,1)
		local shader=shaders[tonumber(id)]
		guiSetVisible(UI.saveWindow,true)
		guiBringToFront(UI.saveWindow)
		local newShader={}
		for id,data in pairs(shader) do
			if id~="shader" and id~="texture" then
				newShader[id]=data
			end
		end
		guiSetText(UI.saveMemo,toJSON(newShader))
	end,false)
	
	addEventHandler("onClientGUIClick",UI.loadShader,function()
		guiSetVisible(UI.loadWindow,true)
		guiBringToFront(UI.loadWindow)
	end,false)
	
	addEventHandler("onClientGUIClick",UI.closeLoad,function()
		guiSetVisible(UI.window,true)
		guiSetVisible(UI.saveWindow,false)
	end,false)
	
	addEventHandler("onClientGUIClick",UI.loadLoad,function()
		guiSetVisible(UI.window,true)
		guiSetVisible(UI.loadWindow,false)
		local json=guiGetText(UI.loadMemo)
		local tab=fromJSON(json)
		if tab==false then return end
		local row=guiGridListAddRow(UI.list)
		guiGridListSetItemText(UI.list,row,1,#shaders+1,false,false)
		guiGridListSetItemText(UI.list,row,2,tab.name,false,false)
		shaders[#shaders+1]={name=tab.name,textures=tab.textures,shader=dxCreateShader ("shader.fx",1,500),fileName=tab.fileName}
		if tab.fileName==nil then return end
		shaders[#shaders].texture=dxCreateTexture(tab.fileName)
	end,false)
	
	addEventHandler("onClientGUIClick",UI.generateLua,function()
		guiSetVisible(UI.saveWindow,true)
		guiBringToFront(UI.saveWindow)
		local shaderString=""
		for id,data in pairs(shaders) do
			local substring="[\""..tostring(data.fileName).."\"]={"
			for _,texture in pairs(data.textures) do
				substring=substring.."\""..texture.."\","
			end
			local substring=substring.."},\n"
			shaderString=shaderString..substring
		end
		guiSetText(UI.saveMemo,[[
local shaders={
]]..shaderString..[[}
function setupShaders()
	for fileName,textures in pairs(shaders) do
		local shader = dxCreateShader ("shader.fx",1,100)
		local texture = dxCreateTexture (fileName)
		dxSetShaderValue (shader,"CUSTOMTEX0", texture )
		for _,texture in pairs(textures) do
			engineApplyShaderToWorldTexture(shader,texture)
		end
	end
end
setupShaders()
		]])
	end,false)
	
	addEventHandler("onClientGUIClick",UI.generateLuaLoop,function()
		guiSetVisible(UI.saveWindow,true)
		guiBringToFront(UI.saveWindow)
		local shaderString=""
		for id,data in pairs(shaders) do
			local substring="[\""..tostring(data.fileName).."\"]={"
			for _,texture in pairs(data.textures) do
				substring=substring.."\""..texture.."\","
			end
			local substring=substring.."},\n"
			shaderString=shaderString..substring
		end
		guiSetText(UI.saveMemo,[[
local shaders={
]]..shaderString..[[}
function setupShaders()
	for fileName,textures in pairs(shaders) do
		local shader = dxCreateShader ("shader.fx",1,100,false,"object")
		local texture = dxCreateTexture (fileName)
		dxSetShaderValue (shader,"CUSTOMTEX0", texture )
		shaders[fileName].shader=shader
	end
end
setupShaders()

-- code for object creation loop (assuming object is identified as "object"
for _,data in pairs(shaders) do
	local shader=data.shader
	for _,texture in pairs(data) do
		if type(texture)=="string" then
			engineApplyShaderToWorldTexture(shader,texture,object)
		end
	end
end
		]])
	end,false)
	
	addEventHandler("onClientGUIClick",UI.togglePreview,function()
		if previewing==true then
			for _,shader in pairs(getElementsByType("shader")) do
				destroyElement(shader)
			end
			previewing=false
		else
			for id,shader in pairs(shaders) do
				if shader.removed~=true and shader.fileName~=nil then
					local shad = dxCreateShader ("shader.fx",1,500)
					local texture = shader.texture
					dxSetShaderValue (shad,"CUSTOMTEX0", texture )
					for _,texture in pairs(shader.textures) do
						engineApplyShaderToWorldTexture(shad,texture)
					end
				end
			end
			previewing=true
		end
	end,false)
	
	addEventHandler("onClientGUIClick",UI.closeSave,function()
		guiSetVisible(UI.window,true)
		guiSetVisible(UI.saveWindow,false)
	end,false)
	
	addEventHandler("onClientGUIClick",UI.close,function()
		guiSetVisible(UI.window,false)
		showCursor(false)
	end,false)
	
	
	
end
createUI()

function createShaderUI()
	shaderUI.newWindow=guiCreateWindow(screenx*0.5-125,screeny*0.5-200,250,100,"New shader",false)
	shaderUI.nameEdit=guiCreateEdit(25,25,200,30,"name",false,shaderUI.newWindow)
	shaderUI.create=guiCreateButton(25,60,200,30,"create",false,shaderUI.newWindow)
	
	addEventHandler("onClientGUIClick",shaderUI.create,function()
		guiSetVisible(shaderUI.newWindow,false)
		guiSetVisible(shaderUI.editWindow,true)
		local name=guiGetText(shaderUI.nameEdit)
		local row=guiGridListAddRow(UI.list)
		guiSetText(shaderUI.nameLabel,name)
		guiGridListSetItemText(UI.list,row,1,#shaders+1,false,false)
		guiGridListSetItemText(UI.list,row,2,name,false,false)
		shaders[#shaders+1]={name=name,textures={},shader=dxCreateShader ("shader.fx",1,500)}
		currentShader=shaders[#shaders]
		guiGridListClear(shaderUI.targets)
	end,false)
	
	shaderUI.editWindow=guiCreateWindow(screenx*0.5-250,screeny*0.5-200,500,400,"Edit shader",false)
	guiCreateLabel(250,25,375,30,"Current texture:",false,shaderUI.editWindow)
	
	shaderUI.nameLabel=guiCreateEdit(25,60,200,30,"Name",false,shaderUI.editWindow)
	shaderUI.close=guiCreateButton(275,370,200,30,"Close",false,shaderUI.editWindow)
	
	guiCreateLabel(25,25,200,30,"Shader : ",false,shaderUI.editWindow)
	shaderUI.selectImage=guiCreateButton(275,325,200,30,"select image",false,shaderUI.editWindow)
	shaderUI.image=guiCreateStaticImage(250,55,225,225,"images/none.png",false,shaderUI.editWindow)
	shaderUI.targets=guiCreateGridList(25,100,200,250,false,shaderUI.editWindow)
	guiGridListAddColumn(shaderUI.targets,"Texture",0.85)
	shaderUI.addTexture=guiCreateButton(25,370,200,30,"Add texture",false,shaderUI.editWindow)
	
	
	guiSetVisible(shaderUI.newWindow,false)
	guiSetVisible(shaderUI.editWindow,false)
	
	addEventHandler("onClientGUIClick",shaderUI.close,function()
		guiSetVisible(UI.window,true)
		guiSetVisible(shaderUI.editWindow,false)
	end,false)
	
	addEventHandler("onClientGUIClick",shaderUI.addTexture,function()
		if textureUI.window==nil then
			createTextureUI()
		end
		guiSetVisible(textureUI.window,true)
		guiSetVisible(shaderUI.editWindow,false)
		fillTexutres()
	end,false)
	
	addEventHandler("onClientGUIClick",shaderUI.selectImage,function()
		if imagesUI.window==nil then
			createImageSelector()
		end
		guiSetVisible(shaderUI.editWindow,false)
		guiSetVisible(imagesUI.window,true)
	end,false)
end
createShaderUI()

function createImageSelector()
	imagesUI.window=guiCreateWindow(screenx*0.5-125,screeny*0.5-200,250,100,"Select Image Name",false)
	imagesUI.nameEdit=guiCreateEdit(25,25,200,30,"name",false,imagesUI.window)
	imagesUI.select=guiCreateButton(25,60,200,30,"Select",false,imagesUI.window)
	addEventHandler("onClientGUIClick",imagesUI.select,function()
		local fileName=guiGetText(imagesUI.nameEdit)
		if fileExists(fileName)==true then
			currentShader.fileName=fileName
			currentShader.texture=dxCreateTexture(fileName)
		end
		guiSetVisible(imagesUI.window,false)
		guiSetVisible(shaderUI.editWindow,true)
	end,false)
end

function createTextureUI()
	textureUI.window=guiCreateWindow(screenx*0.5-150,screeny*0.5-200,300,400,"Select Texture",false)
	textureUI.textures=guiCreateGridList(25,25,250,300,false,textureUI.window)
	guiGridListAddColumn(textureUI.textures,"Name",5)
	textureUI.closeButton=guiCreateButton(25,350,100,30,"Close",false,textureUI.window)
	textureUI.addButton=guiCreateButton(175,350,100,30,"Add",false,textureUI.window)
	guiSetVisible(textureUI.window,false)
	
	function fillTexutres()
		guiGridListClear(textureUI.textures)
		local textures=engineGetVisibleTextureNames()
		table.sort(textures)
		for _,texture in pairs(textures) do
			local row=guiGridListAddRow(textureUI.textures)
			guiGridListSetItemText(textureUI.textures,row,1,texture,false,false)
		end
	end
	
	addEventHandler("onClientGUIClick",textureUI.closeButton,function()
		guiSetVisible(textureUI.window,false)
		guiSetVisible(shaderUI.editWindow,true)	
		if prevTexture~=nil then
			engineRemoveShaderFromWorldTexture(dummyShader,prevTexture)
			prevTexture=nil
		end
	end,false)
	
	addEventHandler("onClientGUIClick",textureUI.textures,function()
		local row=guiGridListGetSelectedItem(textureUI.textures)
		if row==-1 then return end
		if dummyShader==nil or dummyShader==false or isElement(dummyShader)==false or getElementType(dummyShader)~="shader" then
			setupDummy()
		end
		if prevTexture~=nil then
			engineRemoveShaderFromWorldTexture(dummyShader,prevTexture)
		end
		local texture=guiGridListGetItemText(textureUI.textures,row,1)
		engineApplyShaderToWorldTexture(dummyShader,texture)
		prevTexture=texture
	end,false)
	
	addEventHandler("onClientGUIClick",textureUI.addButton,function()
		local row=guiGridListGetSelectedItem(textureUI.textures)
		if row==-1 then return end	
		local texture=guiGridListGetItemText(textureUI.textures,row,1)
		local textureRow=guiGridListAddRow(shaderUI.targets)
		currentShader.textures[#currentShader.textures+1]=texture
		guiGridListSetItemText(shaderUI.targets,textureRow,1,texture,false,false)
		guiSetVisible(textureUI.window,false)
		guiSetVisible(shaderUI.editWindow,true)		
		if prevTexture~=nil then
			engineRemoveShaderFromWorldTexture(dummyShader,prevTexture)
			prevTexture=nil
		end
	end,false)
end

function setupDummy()
	dummyShader = dxCreateShader ("shader.fx",1,500)
	local texture = dxCreateTexture ("images/dummy.png")
	dxSetShaderValue (dummyShader,"CUSTOMTEX0", texture )
end
setupDummy()

function drawTexture()
	if currentShader==nil or currentShader.texture==nil or shaderUI.editWindow==nil or guiGetVisible(shaderUI.editWindow)==false then return end
	local x,y=guiGetPosition(shaderUI.image,false)
	local px,py=guiGetPosition(shaderUI.editWindow,false)
	dxDrawImage(x+px,y+py,225,225,currentShader.texture,0,0,0,tocolor(255,255,255),true)
end
addEventHandler("onClientRender",getRootElement(),drawTexture)

function openUI()
	guiSetVisible(UI.window,true)
	guiSetInputMode("no_binds_when_editing")
	showCursor(true)
end
openUI()
addCommandHandler("shaders",openUI)

