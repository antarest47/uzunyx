/*
    SPDX-FileCopyrightText: 2026 emi <285864120+antarest47@users.noreply.github.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <effect/effect.h>
#include <effect/effectwindow.h>
#include <effect/timeline.h>

#include <QHash>

#include <chrono>

namespace KWin
{

// Open and close animation for windows: they rise into place (up 16 px,
// from 97 % size, fading in) and sink back out. While animating, the window
// is drawn above the rest: on close KWin activates and raises another
// window, which hid the animation (as it did with Magic Lamp on minimize).
class UzunyxOpenCloseEffect : public Effect
{
    Q_OBJECT

public:
    UzunyxOpenCloseEffect();
    ~UzunyxOpenCloseEffect() override;

    void reconfigure(ReconfigureFlags flags) override;
    void prePaintScreen(ScreenPrePaintData &data) override;
    void prePaintWindow(RenderView *view, EffectWindow *w, WindowPrePaintData &data) override;
    void paintWindow(const RenderTarget &renderTarget, const RenderViewport &viewport, EffectWindow *w, int mask, const Region &deviceRegion, WindowPaintData &data) override;
    void postPaintScreen() override;
    bool isActive() const override;

    // After KWin's Maximize effect (60): apps that open maximized (Gwenview,
    // Claude) get a maximize animation right after appearing, and setting
    // the scale and translation last overrides it while this one plays.
    int requestedEffectChainPosition() const override
    {
        return 70;
    }

    static bool supported();

private Q_SLOTS:
    void slotWindowAdded(KWin::EffectWindow *w);
    void slotWindowClosed(KWin::EffectWindow *w);
    void slotWindowDeleted(KWin::EffectWindow *w);
    void slotWindowDataChanged(KWin::EffectWindow *w, int role);

private:
    struct Animation
    {
        TimeLine timeLine;
        bool closing = false;
        // Holds a closed window until the animation ends (refWindow). Not an
        // EffectWindowDeletedRef: when KWin quits it destroys the windows
        // anyway, and dropping that ref then from windowDeleted freed the
        // window twice (KWin crashed on logout).
        bool referenced = false;
    };

    static bool isAnimatable(EffectWindow *w);
    bool grabbedByOther(EffectWindow *w, int role) const;
    void start(EffectWindow *w, bool closing);
    void stop(EffectWindow *w);
    void log(const QString &text) const;

    QHash<EffectWindow *, Animation> m_animations;
    bool m_debug = false;
    std::chrono::milliseconds m_openDuration;
    std::chrono::milliseconds m_closeDuration;
};

} // namespace KWin
