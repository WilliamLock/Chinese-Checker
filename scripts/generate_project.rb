#!/usr/bin/env ruby
# frozen_string_literal: true

require "xcodeproj"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
PROJECT_PATH = File.join(ROOT, "ChineseChecker.xcodeproj")
APP_FILES = Dir.glob(File.join(ROOT, "Shared/**/*.swift")).sort
ASSET_CATALOG = File.join(ROOT, "Shared/Assets.xcassets")

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH)

main_group = project.main_group
file_refs = APP_FILES.map do |file|
  main_group.new_file(file.sub("#{ROOT}/", ""))
end
asset_ref = File.exist?(ASSET_CATALOG) ? main_group.new_file("Shared/Assets.xcassets") : nil

def add_app_target(project, name:, platform:, deployment_target:, bundle_suffix:, supported_destinations:, display_name: "Duo Chinese Checkers", swift_flags: nil, lite_ads: false)
  target = project.new_target(:application, name, platform, deployment_target)
  target.build_configurations.each do |config|
    if platform == :ios || platform == :osx
      config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
    elsif platform == :tvos
      config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIconTV"
    elsif platform == :visionos
      config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIconVision"
    end
    config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
    config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
    config.build_settings["DEVELOPMENT_TEAM"] = "AK2DM5M5FX"
    config.build_settings["ENABLE_PREVIEWS"] = "YES"
    config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
    config.build_settings["INFOPLIST_KEY_CFBundleDisplayName"] = display_name
    config.build_settings["INFOPLIST_KEY_LSApplicationCategoryType"] = "public.app-category.games"
    config.build_settings["MARKETING_VERSION"] = "1.0"
    config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = bundle_suffix.start_with?("lite") ? "com.lockstudio.duochinesecheckers.lite" : "com.lockstudio.duochinesecheckers"
    config.build_settings["PRODUCT_NAME"] = display_name
    config.build_settings["SUPPORTED_PLATFORMS"] = supported_destinations
    config.build_settings["SWIFT_VERSION"] = "6.0"
    config.build_settings["TARGETED_DEVICE_FAMILY"] = target_device_family(platform)
    config.build_settings["OTHER_SWIFT_FLAGS"] = "$(inherited) #{swift_flags}" if swift_flags
    if platform == :ios
      config.build_settings["INFOPLIST_KEY_UIRequiresFullScreen"] = "YES"
      config.build_settings["INFOPLIST_KEY_UILaunchScreen_Generation"] = "YES"
      config.build_settings["INFOPLIST_KEY_UISupportedInterfaceOrientations"] = "UIInterfaceOrientationPortrait"
      config.build_settings["INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad"] = "UIInterfaceOrientationPortrait"
      if lite_ads
        config.build_settings["INFOPLIST_KEY_GADApplicationIdentifier"] = "ca-app-pub-3940256099942544~1458002511"
      end
    elsif [:tvos, :visionos].include?(platform)
      config.build_settings["INFOPLIST_KEY_UISupportedInterfaceOrientations"] = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
    elsif platform == :osx
      config.build_settings["CODE_SIGN_ENTITLEMENTS"] = "Shared/Entitlements/ChineseChecker-macOS.entitlements"
    end
  end

  if platform == :visionos
    phase = target.new_shell_script_build_phase("Patch visionOS App Icon Info.plist")
    phase.shell_script = <<~SCRIPT
      set -e
      PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
      if [ -f "$PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Delete :CFBundleIcons" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :CFBundleIcons dict" "$PLIST"
        /usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon string AppIconVision" "$PLIST"
      fi
    SCRIPT
  end

  target
end

def target_device_family(platform)
  case platform
  when :ios
    "1,2"
  when :tvos
    "3"
  when :visionos
    "7"
  else
    ""
  end
end

targets = [
  add_app_target(project, name: "ChineseChecker iOS", platform: :ios, deployment_target: "17.0", bundle_suffix: "ios", supported_destinations: "iphoneos iphonesimulator"),
  add_app_target(project, name: "ChineseChecker macOS", platform: :osx, deployment_target: "14.0", bundle_suffix: "macos", supported_destinations: "macosx"),
  add_app_target(project, name: "ChineseChecker tvOS", platform: :tvos, deployment_target: "17.0", bundle_suffix: "tvos", supported_destinations: "appletvos appletvsimulator"),
  add_app_target(project, name: "ChineseChecker visionOS", platform: :visionos, deployment_target: "1.0", bundle_suffix: "visionos", supported_destinations: "xros xrsimulator"),
  add_app_target(project, name: "ChineseChecker Lite iOS", platform: :ios, deployment_target: "17.0", bundle_suffix: "lite.ios", supported_destinations: "iphoneos iphonesimulator", display_name: "Duo Chinese Checkers Lite", swift_flags: "-DLITE_VERSION", lite_ads: true)
]

targets.each do |target|
  file_refs.each { |file_ref| target.add_file_references([file_ref]) }
  target.add_resources([asset_ref]) if asset_ref
end

lite_ios_target = targets.find { |target| target.name == "ChineseChecker Lite iOS" }
if lite_ios_target && ENV["ENABLE_LITE_ADS_PACKAGE"] == "1"
  package = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package.repositoryURL = "https://github.com/googleads/swift-package-manager-google-mobile-ads.git"
  package.requirement = { "kind" => "upToNextMajorVersion", "minimumVersion" => "13.6.0" }
  project.root_object.package_references << package

  product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product.product_name = "GoogleMobileAds"
  product.package = package
  lite_ios_target.package_product_dependencies << product

  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = product
  lite_ios_target.frameworks_build_phase.files << build_file
end

project.recreate_user_schemes
project.save

user_schemes = File.join(PROJECT_PATH, "xcuserdata", "#{ENV.fetch("USER", "wlock")}.xcuserdatad", "xcschemes")
shared_schemes = File.join(PROJECT_PATH, "xcshareddata", "xcschemes")
if Dir.exist?(user_schemes)
  FileUtils.mkdir_p(shared_schemes)
  FileUtils.cp(Dir.glob(File.join(user_schemes, "*.xcscheme")), shared_schemes)
  FileUtils.rm_rf(user_schemes)
end
