# encoding: utf-8
#

# lightParam
# building_id, major, mac, [minor, tmp, lst, errcode]

# cameraConfig
# building_id, mac, win_type, [(minor), carpos, x, y]

class RKeys


	def self.get_cfg_key(building_id, mac, index)
		key = "cfg_#{building_id}_#{mac}_#{index}"
		key
	end

	def self.get_info_key(building_id, mac, index)
		key = "#{mac}_#{index}"
		key
	end
end
