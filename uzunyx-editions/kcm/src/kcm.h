#pragma once

#include <KQuickConfigModule>

#include <QUrl>

class QProcess;

// System Settings module that switches between the Uzunyx editions (Akane,
// Sora). The work is done by the uzunyx-edition command; this only picks the
// edition and the parts to change, and runs it on Apply. It also picks how
// windows get the focus (KWin's FocusPolicy and AutoRaise in kwinrc).
class UzunyxEditionsKcm : public KQuickConfigModule
{
    Q_OBJECT
    Q_PROPERTY(QString currentEdition READ currentEdition NOTIFY currentEditionChanged)
    Q_PROPERTY(QString selectedEdition READ selectedEdition WRITE setSelectedEdition NOTIFY selectedEditionChanged)
    Q_PROPERTY(bool applyTheme READ applyTheme WRITE setApplyTheme NOTIFY optionsChanged)
    Q_PROPERTY(bool applyWallpaper READ applyWallpaper WRITE setApplyWallpaper NOTIFY optionsChanged)
    Q_PROPERTY(bool applyLock READ applyLock WRITE setApplyLock NOTIFY optionsChanged)
    Q_PROPERTY(bool applyLauncher READ applyLauncher WRITE setApplyLauncher NOTIFY optionsChanged)
    Q_PROPERTY(bool applySddm READ applySddm WRITE setApplySddm NOTIFY optionsChanged)
    Q_PROPERTY(bool applyPlymouth READ applyPlymouth WRITE setApplyPlymouth NOTIFY optionsChanged)
    Q_PROPERTY(bool plymouthAvailable READ plymouthAvailable CONSTANT)
    Q_PROPERTY(int focusMode READ focusMode WRITE setFocusMode NOTIFY focusModeChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString errorText READ errorText NOTIFY errorTextChanged)

public:
    UzunyxEditionsKcm(QObject *parent, const KPluginMetaData &data);
    ~UzunyxEditionsKcm() override;

    QString currentEdition() const { return m_current; }
    QString selectedEdition() const { return m_selected; }
    void setSelectedEdition(const QString &edition);

    bool applyTheme() const { return m_theme; }
    bool applyWallpaper() const { return m_wallpaper; }
    bool applyLock() const { return m_lock; }
    bool applyLauncher() const { return m_launcher; }
    bool applySddm() const { return m_sddm; }
    bool applyPlymouth() const { return m_plymouth; }
    void setApplyTheme(bool on);
    void setApplyWallpaper(bool on);
    void setApplyLock(bool on);
    void setApplyLauncher(bool on);
    void setApplySddm(bool on);
    void setApplyPlymouth(bool on);

    // The boot splash themes (uzunyx-plymouth) are installed.
    bool plymouthAvailable() const;

    // How windows get the focus.
    enum FocusMode {
        ClickToFocus = 0,
        FocusFollowsMouse = 1, // and stays below until clicked
        FocusFollowsMouseRaise = 2, // and comes to the front
    };
    Q_ENUM(FocusMode)
    int focusMode() const { return m_focus; }
    void setFocusMode(int mode);

    bool busy() const { return m_busy; }
    QString errorText() const { return m_error; }

    // First image of an installed wallpaper package, for the previews.
    Q_INVOKABLE QUrl wallpaperPreview(const QString &package) const;

    // The window listing the shortcuts (uzunyx-keys).
    Q_INVOKABLE bool shortcutsAvailable() const;
    Q_INVOKABLE void showShortcuts();

    void load() override;
    void save() override;
    void defaults() override;

Q_SIGNALS:
    void currentEditionChanged();
    void selectedEditionChanged();
    void focusModeChanged();
    void optionsChanged();
    void busyChanged();
    void errorTextChanged();

private:
    void setOption(bool &option, bool on);
    void updateNeedsSave();
    bool editionPending() const;
    int loadFocusMode() const;
    void saveFocusMode();
    void setBusy(bool busy);
    void setError(const QString &error);

    QString m_current;
    QString m_selected;
    bool m_theme = true;
    bool m_wallpaper = true;
    bool m_lock = true;
    bool m_launcher = true;
    bool m_sddm = false;
    bool m_plymouth = false;
    int m_focus = ClickToFocus;
    int m_savedFocus = ClickToFocus;
    bool m_busy = false;
    QProcess *m_process = nullptr;
    QString m_error;
};
