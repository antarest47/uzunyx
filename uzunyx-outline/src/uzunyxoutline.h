/*
    SPDX-FileCopyrightText: 2026 emi <285864120+antarest47@users.noreply.github.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <effect/effect.h>

#include <KSharedConfig>

#include <QColor>

#include <memory>
#include <unordered_map>
#include <unordered_set>

namespace KWin
{

class EffectWindow;
class OutlinedBorderItem;

/*
 * Thin outline around windows that draw their own frame (Firefox, Electron,
 * GTK/libadwaita), like the 1 px outline of the uzunyx decoration.
 *
 * It does not paint anything itself: each window gets an OutlinedBorderItem
 * (the scene item KWin uses for the outline of decorations) as a child of
 * its WindowItem, so KWin draws it live with the window, also inside other
 * effects (magic lamp, fade) and hidden with it when minimized.
 *
 * While the uzunyxtiling script is on, the active window's is thicker and in
 * the edition's accent: there, with no title bars, it is hard to tell it apart.
 */
class UzunyxOutlineEffect : public Effect
{
    Q_OBJECT

public:
    UzunyxOutlineEffect();
    ~UzunyxOutlineEffect() override;

    bool isActive() const override;

private:
    void readSettings();
    void updateAll();
    bool wantsAccent(EffectWindow *window) const;
    void addWindow(EffectWindow *window);
    void removeWindow(EffectWindow *window);
    void updateWindow(EffectWindow *window);
    void updateGeometry(EffectWindow *window);
    void updateRadius(EffectWindow *window, bool wanted);
    bool wantsOutline(EffectWindow *window) const;

    std::unordered_map<EffectWindow *, std::unique_ptr<OutlinedBorderItem>> m_outlines;
    std::unordered_set<EffectWindow *> m_rounded;
    KSharedConfigPtr m_kwinConfig;
    KSharedConfigPtr m_globalConfig;
    bool m_tiling = false;
    QColor m_accent;
};

} // namespace KWin
