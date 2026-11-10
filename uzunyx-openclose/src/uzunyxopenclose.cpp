/*
    SPDX-FileCopyrightText: 2026 emi <285864120+antarest47@users.noreply.github.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "uzunyxopenclose.h"

#include <effect/effecthandler.h>

#include <KConfigGroup>
#include <KSharedConfig>

#include <QDebug>

using namespace std::chrono_literals;

namespace KWin
{

namespace
{
// How far below and how much smaller the window starts.
constexpr qreal s_riseDistance = 16;
constexpr qreal s_startScale = 0.97;
}

UzunyxOpenCloseEffect::UzunyxOpenCloseEffect()
{
    reconfigure(ReconfigureAll);

    connect(effects, &EffectsHandler::windowAdded, this, &UzunyxOpenCloseEffect::slotWindowAdded);
    connect(effects, &EffectsHandler::windowClosed, this, &UzunyxOpenCloseEffect::slotWindowClosed);
    connect(effects, &EffectsHandler::windowDeleted, this, &UzunyxOpenCloseEffect::slotWindowDeleted);
    connect(effects, &EffectsHandler::windowDataChanged, this, &UzunyxOpenCloseEffect::slotWindowDataChanged);
}

UzunyxOpenCloseEffect::~UzunyxOpenCloseEffect()
{
    const auto windows = m_animations.keys();
    for (EffectWindow *w : windows) {
        stop(w);
    }
}

bool UzunyxOpenCloseEffect::supported()
{
    return effects->animationsSupported();
}

void UzunyxOpenCloseEffect::reconfigure(ReconfigureFlags)
{
    m_openDuration = animationTime(240ms);
    m_closeDuration = animationTime(200ms);

    // [Effect-uzunyxopenclose] Debug=true in kwinrc: log what is decided for
    // each window to the session journal.
    effects->config()->reparseConfiguration();
    m_debug = effects->config()->group(QStringLiteral("Effect-uzunyxopenclose")).readEntry("Debug", false);
}

void UzunyxOpenCloseEffect::log(const QString &text) const
{
    if (m_debug) {
        qInfo().noquote() << "uzunyxopenclose:" << text;
    }
}

// Same choice of windows as KWin's Scale effect.
bool UzunyxOpenCloseEffect::isAnimatable(EffectWindow *w)
{
    const QString windowClass = w->windowClass();
    // All of Plasma's windows share one class; only its decorated ones
    // (settings dialogs) are real windows. Panels, popups and Tsunyx aren't.
    if (windowClass.contains(QLatin1String("plasmashell"))) {
        return w->hasDecoration();
    }
    // The logout and splash screens have their own effects; Spectacle's
    // region selector covers the screen.
    if (windowClass.startsWith(QLatin1String("ksmserver")) || windowClass.startsWith(QLatin1String("ksplashqml"))) {
        return false;
    }
    if (windowClass.contains(QLatin1String("spectacle")) && w->isFullScreen()) {
        return false;
    }
    if (w->hasDecoration()) {
        return true;
    }
    if (w->isPopupWindow() || w->isLockScreen() || w->isOutline() || !w->isManaged()) {
        return false;
    }
    return w->isNormalWindow() || w->isDialog();
}

bool UzunyxOpenCloseEffect::grabbedByOther(EffectWindow *w, int role) const
{
    const void *grabber = w->data(role).value<void *>();
    return grabber && grabber != this;
}

void UzunyxOpenCloseEffect::start(EffectWindow *w, bool closing)
{
    // Claim it, so Scale (or Fade) leaves it alone.
    w->setData(closing ? WindowClosedGrabRole : WindowAddedGrabRole, QVariant::fromValue(static_cast<void *>(this)));

    Animation &animation = m_animations[w];
    animation.closing = closing;
    if (closing && !animation.referenced) {
        w->refWindow();
        animation.referenced = true;
    }
    animation.timeLine.reset();
    animation.timeLine.setDirection(TimeLine::Forward);
    animation.timeLine.setDuration(closing ? m_closeDuration : m_openDuration);
    animation.timeLine.setEasingCurve(closing ? QEasingCurve::InCubic : QEasingCurve::OutCubic);

    effects->setElevatedWindow(w, true);
    w->setData(WindowForceBlurRole, true);
    w->setData(WindowForceBackgroundContrastRole, true);
    w->addRepaintFull();
}

void UzunyxOpenCloseEffect::slotWindowAdded(EffectWindow *w)
{
    const bool animate = !effects->hasActiveFullScreenEffect() && isAnimatable(w) && w->isVisible()
        && !grabbedByOther(w, WindowAddedGrabRole);
    log(QStringLiteral("open %1 \"%2\": %3").arg(w->windowClass(), w->caption(), animate ? QStringLiteral("animated") : QStringLiteral("skipped")));
    if (animate) {
        start(w, false);
    }
}

void UzunyxOpenCloseEffect::slotWindowClosed(EffectWindow *w)
{
    const bool animate = !effects->hasActiveFullScreenEffect() && isAnimatable(w) && w->isVisible()
        && !w->skipsCloseAnimation() && !grabbedByOther(w, WindowClosedGrabRole);
    log(QStringLiteral("close %1: %2").arg(w->windowClass(), animate ? QStringLiteral("animated") : QStringLiteral("skipped")));
    if (animate) {
        start(w, true);
    } else {
        stop(w);
    }
}

// Normally the window is only deleted after stop() released it; when KWin
// quits it is deleted while still animating: forget it without unref.
void UzunyxOpenCloseEffect::slotWindowDeleted(EffectWindow *w)
{
    if (m_animations.remove(w)) {
        effects->setElevatedWindow(w, false);
    }
}

// Another effect took the window over (e.g. Genie Anywhere): let it.
void UzunyxOpenCloseEffect::slotWindowDataChanged(EffectWindow *w, int role)
{
    const auto it = m_animations.constFind(w);
    if (it == m_animations.constEnd() || (role != WindowAddedGrabRole && role != WindowClosedGrabRole)) {
        return;
    }
    if (it->closing == (role == WindowClosedGrabRole) && grabbedByOther(w, role)) {
        log(QStringLiteral("%1 taken over by another effect").arg(w->windowClass()));
        stop(w);
    }
}

void UzunyxOpenCloseEffect::stop(EffectWindow *w)
{
    if (!m_animations.contains(w)) {
        return;
    }
    const bool referenced = m_animations.value(w).referenced;
    m_animations.remove(w);
    effects->setElevatedWindow(w, false);
    w->setData(WindowForceBlurRole, QVariant());
    w->setData(WindowForceBackgroundContrastRole, QVariant());
    // Last, it may delete the window (windowDeleted then finds nothing).
    if (referenced) {
        w->unrefWindow();
    }
}

void UzunyxOpenCloseEffect::prePaintScreen(ScreenPrePaintData &data)
{
    if (!m_animations.isEmpty()) {
        data.mask |= PAINT_SCREEN_WITH_TRANSFORMED_WINDOWS;
    }
    effects->prePaintScreen(data);
}

void UzunyxOpenCloseEffect::prePaintWindow(RenderView *view, EffectWindow *w, WindowPrePaintData &data)
{
    auto it = m_animations.find(w);
    if (it != m_animations.end()) {
        it->timeLine.advance(view);
        data.setTransformed();
    }
    effects->prePaintWindow(view, w, data);
}

void UzunyxOpenCloseEffect::paintWindow(const RenderTarget &renderTarget, const RenderViewport &viewport, EffectWindow *w, int mask, const Region &deviceRegion, WindowPaintData &data)
{
    const auto it = m_animations.constFind(w);
    if (it != m_animations.constEnd()) {
        // How much of the window is shown: 0 = gone, 1 = in place.
        const qreal value = it->timeLine.value();
        const qreal shown = it->closing ? 1 - value : value;
        const RectF frame = w->frameGeometry();
        const qreal scale = s_startScale + (1 - s_startScale) * shown;
        // Set, not multiplied: replaces Maximize's size animation.
        data.setXScale(scale);
        data.setYScale(scale);
        data.setXTranslation((1 - scale) * frame.width() / 2);
        data.setYTranslation((1 - scale) * frame.height() / 2 + s_riseDistance * (1 - shown));
        data.multiplyOpacity(shown);
    }
    effects->paintWindow(renderTarget, viewport, w, mask, deviceRegion, data);
}

void UzunyxOpenCloseEffect::postPaintScreen()
{
    QList<EffectWindow *> finished;
    for (auto it = m_animations.cbegin(); it != m_animations.cend(); ++it) {
        if (it->timeLine.done()) {
            finished.append(it.key());
        }
    }
    for (EffectWindow *w : std::as_const(finished)) {
        stop(w);
    }
    if (!m_animations.isEmpty()) {
        effects->addRepaintFull();
    }
    effects->postPaintScreen();
}

bool UzunyxOpenCloseEffect::isActive() const
{
    return !m_animations.isEmpty();
}

} // namespace KWin

#include "moc_uzunyxopenclose.cpp"
