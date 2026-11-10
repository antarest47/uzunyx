/*
    SPDX-FileCopyrightText: 2026 emi <285864120+antarest47@users.noreply.github.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "uzunyxoutline.h"

#include <effect/effecthandler.h>
#include <effect/effectwindow.h>
#include <scene/borderoutline.h>
#include <scene/outlinedborderitem.h>
#include <scene/windowitem.h>
#include <window.h>

#include <KConfigGroup>
#include <KConfigWatcher>

namespace KWin
{

// Same look as the uzunyx decoration: 1 px, white at 25 % (12 % when
// inactive), following the 8 px rounded corners. The line covers the
// outermost pixel of the window, so its outer edge has the 8 px radius.
static constexpr qreal s_thickness = 1;
static constexpr qreal s_radius = 8;
static constexpr qreal s_activeAlpha = 0.25;
static constexpr qreal s_inactiveAlpha = 0.12;
// The active window while the windows are tiled.
static constexpr qreal s_accentThickness = 3;
// Above the shadow and the window contents (both z 0).
static constexpr int s_z = 1;

UzunyxOutlineEffect::UzunyxOutlineEffect()
{
    connect(effects, &EffectsHandler::windowAdded, this, &UzunyxOutlineEffect::addWindow);
    connect(effects, &EffectsHandler::windowDeleted, this, &UzunyxOutlineEffect::removeWindow);
    connect(effects, &EffectsHandler::windowActivated, this, &UzunyxOutlineEffect::updateAll);

    m_kwinConfig = KSharedConfig::openConfig(QStringLiteral("kwinrc"));
    m_globalConfig = KSharedConfig::openConfig(QStringLiteral("kdeglobals"));
    readSettings();
    // uzunyx-tiling and the edition change write these with a notification.
    for (const KSharedConfigPtr &config : {m_kwinConfig, m_globalConfig}) {
        const KConfigWatcher::Ptr watcher = KConfigWatcher::create(config);
        connect(watcher.data(), &KConfigWatcher::configChanged, this, [this, watcher]() {
            readSettings();
            updateAll();
        });
    }

    const auto windows = effects->stackingOrder();
    for (EffectWindow *window : windows) {
        addWindow(window);
    }
}

UzunyxOutlineEffect::~UzunyxOutlineEffect() = default;

bool UzunyxOutlineEffect::isActive() const
{
    // KWin draws the outline items; this effect never paints.
    return false;
}

void UzunyxOutlineEffect::readSettings()
{
    m_kwinConfig->reparseConfiguration();
    m_globalConfig->reparseConfiguration();
    m_tiling = KConfigGroup(m_kwinConfig, QStringLiteral("Script-uzunyxtiling")).readEntry("Mode", QStringLiteral("off")) != QLatin1String("off");
    m_accent = KConfigGroup(m_globalConfig, QStringLiteral("Colors:View")).readEntry("DecorationFocus", QColor(Qt::white));
}

void UzunyxOutlineEffect::updateAll()
{
    // updateWindow() may drop entries; walk a copy.
    std::vector<EffectWindow *> windows;
    for (const auto &[window, item] : m_outlines) {
        windows.push_back(window);
    }
    for (EffectWindow *window : windows) {
        updateWindow(window);
    }
}

bool UzunyxOutlineEffect::wantsAccent(EffectWindow *window) const
{
    return m_tiling && window == effects->activeWindow();
}

void UzunyxOutlineEffect::addWindow(EffectWindow *window)
{
    connect(window, &EffectWindow::windowDecorationChanged, this, &UzunyxOutlineEffect::updateWindow);
    connect(window, &EffectWindow::windowFullScreenChanged, this, &UzunyxOutlineEffect::updateWindow);
    connect(window, &EffectWindow::windowFrameGeometryChanged, this, &UzunyxOutlineEffect::updateGeometry);
    updateWindow(window);
}

void UzunyxOutlineEffect::removeWindow(EffectWindow *window)
{
    // Must happen before the WindowItem goes away: the item unlinks itself
    // from its parent when destroyed.
    m_outlines.erase(window);
    m_rounded.erase(window);
}

bool UzunyxOutlineEffect::wantsOutline(EffectWindow *window) const
{
    if (window->hasDecoration() || window->isFullScreen()) {
        return false;
    }
    if (!window->isNormalWindow() && !window->isDialog()) {
        return false;
    }
    if (window->isSpecialWindow() || window->isPopupWindow() || window->isOutline() || window->isLockScreen()) {
        return false;
    }
    // edge-gaps surfaces (1 px) and other tiny windows.
    if (window->width() < 32 || window->height() < 32) {
        return false;
    }
    // Plasma's own windows (Tsunyx menu, KRunner…), the startup splash and
    // the logout screen are not app frames.
    const QString windowClass = window->windowClass();
    static const QLatin1String skipped[] = {QLatin1String("plasmashell"), QLatin1String("krunner"),
                                            QLatin1String("ksplashqml"), QLatin1String("ksmserver")};
    for (const QLatin1String &name : skipped) {
        if (windowClass.contains(name)) {
            return false;
        }
    }
    // Borderless windows covering a whole screen (games, players, splash
    // screens) without being in the fullscreen state.
    const RectF screen = effects->clientArea(FullScreenArea, window);
    return window->frameGeometry() != screen;
}

void UzunyxOutlineEffect::updateRadius(EffectWindow *window, bool wanted)
{
    // Windows that had their decoration removed (noBorder) have square
    // contents: clip them. Apps that draw their own frame round themselves.
    const bool round = wanted && window->window()->noBorder();
    if (round) {
        window->window()->setBorderRadius(BorderRadius(s_radius));
        m_rounded.insert(window);
    } else if (m_rounded.erase(window)) {
        // Only what this effect set: the decoration has its own radius.
        window->window()->setBorderRadius(BorderRadius());
    }
}

void UzunyxOutlineEffect::updateWindow(EffectWindow *window)
{
    // A closed window keeps its outline while it fades out.
    if (window->isDeleted()) {
        return;
    }
    if (!wantsOutline(window)) {
        m_outlines.erase(window);
        updateRadius(window, false);
        return;
    }
    updateRadius(window, true);

    // KWin's border shader blends with premultiplied alpha.
    const qreal alpha = window == effects->activeWindow() ? s_activeAlpha : s_inactiveAlpha;
    const bool accent = wantsAccent(window);
    const QColor color = accent ? m_accent : QColor::fromRgbF(alpha, alpha, alpha, alpha);
    const qreal thickness = accent ? s_accentThickness : s_thickness;
    const BorderOutline outline(thickness, color, BorderRadius(s_radius - thickness));

    auto &item = m_outlines[window];
    if (!item) {
        item = std::make_unique<OutlinedBorderItem>(RectF(), outline, window->windowItem());
        item->setZ(s_z);
    } else {
        item->setOutline(outline);
    }
    updateGeometry(window);
}

void UzunyxOutlineEffect::updateGeometry(EffectWindow *window)
{
    const auto it = m_outlines.find(window);
    const bool wanted = !window->isDeleted() && wantsOutline(window);
    if (it == m_outlines.end()) {
        // Small windows can grow into wanting an outline.
        if (wanted) {
            updateWindow(window);
        }
        return;
    }
    // A window resized to cover the screen loses it (not while closing).
    if (!window->isDeleted() && !wanted) {
        m_outlines.erase(it);
        updateRadius(window, false);
        return;
    }
    // WindowItem coordinates start at the frame's top-left corner.
    const QSizeF size = window->frameGeometry().size();
    const qreal thickness = wantsAccent(window) ? s_accentThickness : s_thickness;
    it->second->setInnerRect(RectF(thickness, thickness, size.width() - 2 * thickness, size.height() - 2 * thickness));
}

} // namespace KWin
