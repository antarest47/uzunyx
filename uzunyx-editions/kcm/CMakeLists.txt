cmake_minimum_required(VERSION 3.20)
project(kcm_uzunyx_editions)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(KF6_MIN_VERSION "6.0.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 CONFIG REQUIRED COMPONENTS Core DBus Qml)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS Config CoreAddons I18n KCMUtils)

add_definitions(-DTRANSLATION_DOMAIN=\"kcm_uzunyx_editions\")

# QML in ui/ (main.qml), built into the plugin; installed with the other
# System Settings modules (plasma/kcms/systemsettings). Also generates
# kcm_uzunyx_editions.desktop from kcm_uzunyx_editions.json (hidden; lets
# KRunner and kcmshell6 open it).
kcmutils_add_qml_kcm(kcm_uzunyx_editions)
target_sources(kcm_uzunyx_editions PRIVATE src/kcm.cpp)
target_link_libraries(kcm_uzunyx_editions PRIVATE
    Qt6::DBus
    Qt6::Qml
    KF6::ConfigCore
    KF6::CoreAddons
    KF6::I18n
    KF6::KCMUtilsQuick
)
