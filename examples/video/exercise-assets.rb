#!/usr/bin/env ruby

require 'mux_ruby'
require 'solid_assert'

SolidAssert.enable_assertions

# Authentication Setup
openapi = MuxRuby.configure do |config|
  config.username = ENV['MUX_TOKEN_ID']
  config.password = ENV['MUX_TOKEN_SECRET']
end

# API Client Initialization
assets_api = MuxRuby::AssetsApi.new

# ========== create-asset ==========
car = MuxRuby::CreateAssetRequest.new
car.input = 'https://storage.googleapis.com/muxdemofiles/mux-video-intro.mp4'
create_response = assets_api.create_asset(car)
assert create_response != nil
assert create_response.data.id != nil
puts "create-asset OK ✅"

# ========== list-assets ==========
assets = assets_api.list_assets()
assert assets != nil
assert assets.data.first.id == create_response.data.id
puts "list-assets OK ✅"

# Wait for the asset to become ready...
if create_response.data.status != 'ready'
  puts "    waiting for asset to become ready..."
  while true do
    # ========== get-asset ==========
    asset = assets_api.get_asset(create_response.data.id)
    assert asset != nil
    assert asset.data.id == create_response.data.id
    if asset.data.status != 'ready'
      puts "Asset not ready yet, sleeping..."
      sleep(1)
    else
      puts "Asset ready checking input info."
      # ========== get-asset-input-info ==========
      input_info = assets_api.get_asset_input_info(asset.data.id)
      assert input_info != nil
      assert input_info.data != nil
      break
    end
  end
end
puts "get-asset OK ✅"
puts "get-asset-input-info OK ✅"

# ========== create-asset-playback-id ==========
cpbr = MuxRuby::CreatePlaybackIDRequest.new
cpbr.policy = MuxRuby::PlaybackPolicy::PUBLIC
pb_id_c = assets_api.create_asset_playback_id(create_response.data.id, cpbr)
assert pb_id_c != nil
assert pb_id_c.data != nil
puts "create-asset-playback-id OK ✅"

# ========== get-asset-playback-id ==========
pb_id = assets_api.get_asset_playback_id(create_response.data.id, pb_id_c.data.id)
assert pb_id != nil
assert pb_id.data != nil
assert pb_id.data.id == pb_id_c.data.id
puts "get-asset-playback-id OK ✅"

# ========== update-asset-mp4-support ==========
mp4_req = MuxRuby::UpdateAssetMP4SupportRequest.new
mp4_req.mp4_support = 'standard'
mp4_asset = assets_api.update_asset_mp4_support(create_response.data.id, mp4_req)
assert mp4_asset != nil
assert mp4_asset.data != nil
assert mp4_asset.data.id == create_response.data.id
assert mp4_asset.data.mp4_support == 'standard'
puts "update-asset-mp4-support OK ✅"

# ========== delete-asset-playback-id ==========
assets_api.delete_asset_playback_id(create_response.data.id, pb_id_c.data.id)
deleted_playback_id_asset = assets_api.get_asset(create_response.data.id)
assert deleted_playback_id_asset.data.playback_ids == nil
puts "delete-asset-playback-id OK ✅"

# ========== delete-asset ==========
assets_api.delete_asset(create_response.data.id)
begin
  assets_api.get_asset(create_response.data.id)
  puts 'Should have errored here.'
  exit 255
rescue MuxRuby::ApiError => e
  assert e != nil
end
puts "delete-asset OK ✅"