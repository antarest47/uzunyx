cmake_minimum_required(VERSION 3.20)
project(kwin-effect-genieanywhere VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 REQUIRED COMPONENTS Core Gui)
find_package(KF6 REQUIRED COMPONENTS Config CoreAddons GlobalAccel WindowSystem)
find_package(KWin REQUIRED)

kcoreaddons_add_plugin(genieanywhere
    SOURCES src/genieanywhere.cpp src/main.cpp
    INSTALL_NAMESPACE "kwin/effects/plugins")

target_link_libraries(genieanywhere PRIVATE
    KWin::kwin
    Qt6::Core
    Qt6::Gui
    KF6::ConfigCore
    KF6::CoreAddons
    KF6::GlobalAccel
    KF6::WindowSystem)
