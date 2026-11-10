cmake_minimum_required(VERSION 3.20)
project(uzunyxaltguard)

# Same as KWin: its headers need C++23.
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(KDE_COMPILERSETTINGS_LEVEL "5.82")

find_package(ECM 6.0.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 CONFIG REQUIRED COMPONENTS Core Gui Widgets)
find_package(KF6 6.0.0 REQUIRED COMPONENTS CoreAddons)
find_package(KWin REQUIRED COMPONENTS kwin)

kcoreaddons_add_plugin(uzunyxaltguard INSTALL_NAMESPACE "kwin/plugins")
target_sources(uzunyxaltguard PRIVATE
    src/uzunyxaltguard.cpp
)
target_link_libraries(uzunyxaltguard PRIVATE KWin::kwin)
