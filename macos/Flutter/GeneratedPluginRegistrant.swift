//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import file_picker
import flutter_secure_storage_darwin
import printing
import record_macos
import shared_preferences_foundation
import speech_to_text
import vosk_flutter_service

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  FlutterSecureStorageDarwinPlugin.register(with: registry.registrar(forPlugin: "FlutterSecureStorageDarwinPlugin"))
  PrintingPlugin.register(with: registry.registrar(forPlugin: "PrintingPlugin"))
  RecordMacOsPlugin.register(with: registry.registrar(forPlugin: "RecordMacOsPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SpeechToTextPlugin.register(with: registry.registrar(forPlugin: "SpeechToTextPlugin"))
  VoskFlutterPlugin.register(with: registry.registrar(forPlugin: "VoskFlutterPlugin"))
}
