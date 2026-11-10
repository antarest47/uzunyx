cmake_minimum_required(VERSION 3.20)
project(uzunyxopenclose)

# Same as KWin: its headers need C++23.
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(KDE_COMPILERSETTINGS_LEVEL "5.82")

set(KF6_MIN_VERSION "6.0.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 CONFIG REQUIRED COMPONENTS Core Gui Widgets)
find_package(KWin REQUIRED COMPONENTS kwin)
# KWIN_EFFECT_FACTORY expands to a Q_OBJECT plugin factory.
list(APPEND CMAKE_AUTOMOC_MACRO_NAMES "KWIN_EFFECT_FACTORY" "KWIN_EFFECT_FACTORY_SUPPORTED")

kcoreaddons_add_plugin(uzunyxopenclose INSTALL_NAMESPACE "kwin/effects/plugins")
target_sources(uzunyxopenclose PRIVATE
    src/main.cpp
    src/uzunyxopenclose.cpp
)
target_link_libraries(uzunyxopenclose PRIVATE KWin::kwin)
