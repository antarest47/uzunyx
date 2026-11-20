/*
    Max gesture: the maximize button also does fullscreen.

    Apps that draw their own title bar (GTK, libadwaita, Electron, Firefox)
    can't get a fourth button, but their maximize button only *asks* KWin to
    maximize. KWin's own decoration does the same. This plugin watches how
    that button was clicked and, for the alternate gestures, turns the
    maximize (or restore) into fullscreen:

    - Shift + click
    - long press: the left button held for LongPress without moving. It
      acts while still held: in the button zone of a title bar (see
      inButtonZone) the plugin lets go of the button for the app at that
      moment, so the app clicks its button, asks to maximize and the window
      goes fullscreen; the real release, later, is swallowed. If it wasn't
      the maximize button, the click is just over (to drag the window from
      there, click again). Elsewhere a long press still counts on release.

    A plain click maximizes and restores as always. Only a maximize change
    right after a click counts, so keyboard shortcuts (Meta+PgUp...) and apps
    maximizing themselves are left alone. The macfullscreen script of
    uzunyx-deco then takes the fullscreen window to a desktop of its own.

    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "input.h"
#include "input_event.h"
#include "plugin.h"
#include "pointer_input.h"
#include "wayland_server.h"
#include "window.h"
#include "workspace.h"

#include <QElapsedTimer>
#include <QPointer>
#include <QTimer>

#include <chrono>
#include <cmath>

#include <linux/input-event-codes.h>

namespace KWin
{

// How long the button has to be held to count as a long press.
static constexpr int LongPress = 450;
// How long after the release the maximize request may still come (the app
// gets the click, then answers).
static constexpr qint64 RequestWindow = 300;
// More movement than this between press and release is a drag, not a press.
static constexpr qreal DragDistance = 8;
// Where title bar buttons are: this high from the top of a window that
// draws its own title bar, and this far from either end of a title bar.
static constexpr qreal ButtonZoneHeight = 56;
static constexpr qreal ButtonZoneWidth = 160;

class MaxGesture : public Plugin, public InputEventFilter
{
    Q_OBJECT

public:
    MaxGesture()
        : InputEventFilter(InputFilterOrder::MouseKeys)
    {
        m_longPress.setSingleShot(true);
        m_longPress.setInterval(LongPress);
        connect(&m_longPress, &QTimer::timeout, this, &MaxGesture::longPressReached);

        input()->installInputEventFilter(this);
        const auto windows = workspace()->windows();
        for (Window *window : windows) {
            watch(window);
        }
        connect(workspace(), &Workspace::windowAdded, this, &MaxGesture::watch);
    }

    ~MaxGesture() override
    {
        if (input()) {
            input()->uninstallInputEventFilter(this);
        }
    }

    bool pointerMotion(PointerMotionEvent *event) override
    {
        if (m_pressed && m_longPress.isActive() && moved(event->position)) {
            m_longPress.stop();
        }
        return false;
    }

    bool pointerButton(PointerButtonEvent *event) override
    {
        if (m_injecting || event->nativeButton != BTN_LEFT) {
            return false;
        }
        if (event->state == PointerButtonState::Pressed) {
            m_pressed = true;
            m_letGo = false;
            m_pressPosition = event->position;
            m_clock.start();
            m_alternate = false;
            m_releasedAt = -1;
            m_longPress.stop();
            if (inButtonZone(event->position)) {
                m_longPress.start();
            }
            return false;
        }
        if (!m_pressed) {
            return false;
        }
        m_pressed = false;
        m_longPress.stop();
        if (m_letGo) {
            // Already let go for the app when the long press was reached.
            m_letGo = false;
            return true;
        }
        const qint64 held = m_clock.elapsed();
        const bool shift = event->modifiers & Qt::ShiftModifier;
        m_alternate = shift || (held >= LongPress && !moved(event->position));
        m_releasedAt = held;
        return false;
    }

private:
    bool moved(const QPointF &position) const
    {
        const QPointF d = position - m_pressPosition;
        return std::hypot(d.x(), d.y()) > DragDistance;
    }

    // Near either end of a title bar: KWin's decoration, or the top of a
    // window that draws its own.
    bool inButtonZone(const QPointF &pos) const
    {
        if (waylandServer()->isScreenLocked()) {
            return false;
        }
        Window *window = input()->findToplevel(pos);
        if (!window || !window->isClient() || window->isFullScreen() || !window->isFullScreenable()) {
            return false;
        }
        const RectF frame = window->frameGeometry();
        if (!frame.contains(pos)) {
            return false;
        }
        const bool titleHeight = window->isDecorated()
            ? pos.y() < window->clientGeometry().top()
            : pos.y() < frame.top() + ButtonZoneHeight;
        const bool nearEnd = pos.x() < frame.left() + ButtonZoneWidth || pos.x() > frame.right() - ButtonZoneWidth;
        return titleHeight && nearEnd;
    }

    // Held long enough without moving: let go of the button for the app now.
    void longPressReached()
    {
        if (!m_pressed) {
            return;
        }
        m_alternate = true;
        m_releasedAt = m_clock.elapsed();
        m_letGo = true;
        const auto now = std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now().time_since_epoch());
        m_injecting = true;
        input()->pointer()->processButton(BTN_LEFT, PointerButtonState::Released, now);
        // Apps only act on a pointer frame (GTK keeps the release until then).
        input()->pointer()->processFrame();
        m_injecting = false;
    }

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
        const bool recent = m_releasedAt >= 0 && m_clock.elapsed() - m_releasedAt <= RequestWindow;
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

    QTimer m_longPress;
    QElapsedTimer m_clock;
    QPointF m_pressPosition;
    qint64 m_releasedAt = -1;
    bool m_pressed = false;
    bool m_letGo = false;
    bool m_injecting = false;
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
