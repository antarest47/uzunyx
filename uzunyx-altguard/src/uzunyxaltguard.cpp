/*
    Alt guard: keeps apps from opening their menu after an Alt shortcut.

    Apps (Firefox, Electron, LibreOffice…) open their menu when Alt is
    pressed and released with no other key in between. When the other key is
    a global shortcut, KWin keeps it, so the app only sees Alt alone. This
    filter notes whether anything else was pressed while Alt was held (a key,
    a mouse button or the wheel) and, if so, sends the focused window a
    key that does nothing just before Alt goes up, as the "menu mask key" of
    AutoHotkey on Windows.

    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "input.h"
#include "input_event.h"
#include "plugin.h"
#include "wayland/display.h"
#include "wayland/seat.h"
#include "wayland_server.h"

#include <linux/input-event-codes.h>

namespace KWin
{

class AltGuard : public Plugin, public InputEventFilter
{
    Q_OBJECT

public:
    AltGuard()
        : InputEventFilter(InputFilterOrder::MouseKeys)
    {
        // For tests: another key to send instead of the default one.
        bool ok = false;
        const quint32 key = qEnvironmentVariableIntValue("UZUNYX_ALTGUARD_KEY", &ok);
        if (ok) {
            m_maskKey = key;
        }
        input()->installInputEventFilter(this);
    }

    ~AltGuard() override
    {
        if (input()) {
            input()->uninstallInputEventFilter(this);
        }
    }

    bool keyboardKey(KeyboardKeyEvent *event) override
    {
        if (event->state == KeyboardKeyState::Repeated) {
            return false;
        }
        const quint32 code = event->nativeScanCode;
        if (code == KEY_LEFTALT || code == KEY_RIGHTALT) {
            if (event->state == KeyboardKeyState::Pressed) {
                m_altDown = true;
                m_used = false;
            } else if (m_altDown) {
                m_altDown = false;
                if (m_used) {
                    mask();
                }
            }
        } else if (event->state == KeyboardKeyState::Pressed) {
            used();
        }
        return false;
    }

    bool pointerButton(PointerButtonEvent *) override
    {
        used();
        return false;
    }

    bool pointerAxis(PointerAxisEvent *) override
    {
        used();
        return false;
    }

private:
    void used()
    {
        if (m_altDown) {
            m_used = true;
        }
    }

    void mask()
    {
        SeatInterface *seat = waylandServer()->seat();
        if (!seat->focusedKeyboardSurface()) {
            return;
        }
        Display *display = waylandServer()->display();
        seat->notifyKeyboardKey(m_maskKey, KeyboardKeyState::Pressed, display->nextSerial());
        seat->notifyKeyboardKey(m_maskKey, KeyboardKeyState::Released, display->nextSerial());
    }

    quint32 m_maskKey = KEY_F24;
    bool m_altDown = false;
    bool m_used = false;
};

class AltGuardFactory : public PluginFactory
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
        return std::make_unique<AltGuard>();
    }
};

} // namespace KWin

#include "uzunyxaltguard.moc"
