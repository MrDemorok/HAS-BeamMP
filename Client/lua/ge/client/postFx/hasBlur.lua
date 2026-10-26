local callbacks = {}

callbacks.onAdd = function()
	local effect = scenetree.findObject("HASBlurPostFX")
	if effect then
		effect.blurAmount = 0.03
	end
end

callbacks.setShaderConsts = function()
	local effect = scenetree.findObject("HASBlurPostFX")
	if effect then
		effect:setShaderConst("$blurAmount", effect.blurAmount or 0.03)
	end
end
rawset(_G, "HASBlurPostFXCallbacks", callbacks)

local shader = scenetree.findObject("HASBlurShader")
if not shader then
	shader = createObject("ShaderData")
	shader.DXVertexShaderFile = "shaders/common/postFx/hasBlur/hasBlurP.hlsl"
	shader.DXPixelShaderFile = "shaders/common/postFx/hasBlur/hasBlurP.hlsl"
	shader.pixVersion = 5.0
	shader:registerObject("HASBlurShader")
end

local effect = scenetree.findObject("HASBlurPostFX")
if not effect then
	effect = createObject("PostEffect")
	effect.isEnabled = false
	effect.allowReflectPass = false
	effect.blurAmount = 0.03
	effect:setField("renderTime", 0, "PFXBeforeBin")
	effect:setField("renderBin", 0, "AfterPostFX")
	effect:setField("shader", 0, "HASBlurShader")
	effect:setField("stateBlock", 0, "PFX_DefaultStateBlock")
	effect:setField("texture", 0, "$backBuffer")
	effect:registerObject("HASBlurPostFX")
end

local M = {}

function M.setEnabled(enabled)
	effect.isEnabled = enabled == true
end

return M
