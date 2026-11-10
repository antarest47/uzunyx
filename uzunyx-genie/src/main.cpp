/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "genieanywhere.h"

namespace KWin
{

KWIN_EFFECT_FACTORY_SUPPORTED(GenieAnywhereEffect,
                              "metadata.json",
                              return GenieAnywhereEffect::supported();)

} // namespace KWin

#include "main.moc"
