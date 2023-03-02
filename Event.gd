extends Node

signal update_settings(section:String, key:String, value:Variant)
signal update_item_settings(item_name:String)
signal update_logs
signal update_items
signal request_window_item_info(item_name:String)
signal request_window_item_options(item_name:String)
signal request_window_options
