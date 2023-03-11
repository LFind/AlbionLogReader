extends Node


signal update_settings(key:Settings.Key, value:Variant)
signal update_item_settings(item_name:String)
signal update_logs
signal update_items
signal removed_all_entries(item:String)

signal request_window_item_info(item_name:String)
signal request_window_item_options(item_name:String)
signal request_window_settings

signal group_update_items(group_name:String)
