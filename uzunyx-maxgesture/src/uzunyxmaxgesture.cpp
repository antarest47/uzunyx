/*
    Max gesture: the maximize button also does fullscreen.

    Apps that draw their own title bar (GTK, libadwaita, Electron, Firefox)
    can't get a fourth button, but their maximize button only *asks* KWin to
    maximize. KWin's own decoration does the same. This plugin watches how
    that button was clicked and, for the alternate gestures, turns the
    maximize (or restore) into fullscreen:

    - Shift + click
    - long press: the left button held for LongPress or more, without
      dragging (dragging a window to the top edge also maximizes on release)

    A plain click maximizes and restores as always. Only a maximize change
    right after a click counts, so keyboard shortcuts (Meta+PgUp...) and apps
    maximizing themselves are left alone. The macfullscreen script of
    uzunyx-deco then takes the fullscreen window to a desktop of its own.

    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "input.h"
#include "input_event.h"
#include "input_event_spy.h"
#include "plugin.h"
#include "wayland_server.h"
#include "window.h"
#include "workspace.h"

#include <QElapsedTimer>
#include <QPointer>

#include <linux/input-event-codes.h>

namespace KWin
{

// How long the button has to be held to count as a long press.
static constexpr qint64 LongPress = 450;
// How long after the release the maximize request may still come (the app
// gets the click, then answers).
static constexpr qint64 RequestWindow = 300;
// More movement than this between press and release is a drag, not a press.
static constexpr qreal DragDistance = 8;

class MaxGesture : public Plugin, public InputEventSpy
{
    Q_OBJECT

public:
    MaxGesture()
    {
        input()->installInputEventSpy(this);
        const auto windows = workspace()->windows();
        for (Window *window : windows) {
            watch(window);
        }
        connect(workspace(), &Workspace::windowAdded, this, &MaxGesture::watch);
    }

    ~MaxGesture() override
    {
        if (input()) {
            input()->uninstallInputEventSpy(this);
        }
    }

    void pointerButton(PointerButtonEvent *event) override
    {
        if (event->nativeButton != BTN_LEFT) {
            return;
        }
        if (event->state == PointerButtonState::Pressed) {
            m_pressed = true;
            m_pressPosition = event->position;
            m_clock.start();
            m_alternate = false;
            m_releasedAt = -1;
        } else if (m_pressed) {
            m_pressed = false;
            const qint64 held = m_clock.elapsed();
            const QPointF moved = event->position - m_pressPosition;
            const bool dragged = std::hypot(moved.x(), moved.y()) > DragDistance;
            const bool shift = event->modifiers & Qt::ShiftModifier;
            m_alternate = shift || (held >= LongPress && !dragged);
            m_releasedAt = held;
        }
    }

private:
    void watch(Window *window)
    {
        if (!window->isClient()) {
            return;
        }
        connect(window, &Window::maximizedChanged, this, [this, window]() {
            maximizedChanged(window);
        });
    }

    // The gesture of the last click, if it was alternate and just happened.
    // Used once: one click, one fullscreen.
    bool takeAlternate()
    {
        if (!m_alternate) {
            return false;
        }
        const bool recent = m_pressed || (m_releasedAt >= 0 && m_clock.elapsed() - m_releasedAt <= RequestWindow);
        m_alternate = false;
        return recent;
    }

    void maximizedChanged(Window *window)
    {
        if (m_busy || window->isDeleted() || window->isFullScreen() || !window->isFullScreenable()) {
            return;
        }
        if (!takeAlternate()) {
            return;
        }
        m_busy = true;
        // Back to the size it had, so leaving fullscreen doesn't land on a
        // maximized window the user didn't ask for.
        if (window->maximizeMode() != MaximizeRestore) {
            window->maximize(MaximizeRestore);
        }
        window->setFullScreen(true);
        m_busy = false;
    }

    QElapsedTimer m_clock;
    QPointF m_pressPosition;
    qint64 m_releasedAt = -1;
    bool m_pressed = false;
    bool m_alternate = false;
    bool m_busy = false;
};

class MaxGestureFactory : public PluginFactory
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID PluginFactory_iid FILE "metadata.json")
    Q_INTERFACES(KWin::PluginFactory)

public:
    std::unique_ptr<Plugin> create() const override
    {
        if (!waylandServer()) {
            return nullptr;
        }
        return std::make_unique<MaxGesture>();
    }
};

} // namespace KWin

#include "uzunyxmaxgesture.moc"
