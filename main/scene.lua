local M={
}

local _order=0
function M.order()
	_order=_order+1
	return _order
end

M.monsters={}
return M