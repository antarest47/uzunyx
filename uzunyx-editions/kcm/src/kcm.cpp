#include "kcm.h"

#include <KConfigGroup>
#include <KLocalizedString>
#include <KPluginFactory>
#include <KSharedConfig>

#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>

K_PLUGIN_CLASS_WITH_JSON(UzunyxEditionsKcm, "../kcm_uzunyx_editions.json")

namespace
{
// Global theme of each edition (same ids as uzunyx-edition).
const QList<std::pair<QString, QString>> s_editions = {
    {QStringLiteral("akane"), QStringLiteral("org.uzunyx.desktop")},
    {QStringLiteral("sora"), QStringLiteral("org.uzunyx.sora")},
};
}

UzunyxEditionsKcm::UzunyxEditionsKcm(QObject *parent, const KPluginMetaData &data)
    : KQuickConfigModule(parent, data)
{
    setButtons(Apply | Default);
}

UzunyxEditionsKcm::~UzunyxEditionsKcm()
{
    // OK in kcmshell6 / System Settings saves and closes the module
    // right away; QProcess would kill uzunyx-edition halfway (nothing
    // applied). Let it finish (the boot screen can take half a minute),
    // without the finished handler, which would reload a module that is
    // being destroyed.
    if (m_process) {
        disconnect(m_process, nullptr, this, nullptr);
        m_process->waitForFinished(-1);
    }
}

bool UzunyxEditionsKcm::shortcutsAvailable() const
{
    return !QStandardPaths::findExecutable(QStringLiteral("uzunyx-keys")).isEmpty();
}

void UzunyxEditionsKcm::showShortcuts()
{
    QProcess::startDetached(QStringLiteral("uzunyx-keys"), {});
}

void UzunyxEditionsKcm::load()
{
    // kdeglobals with its cascade: the system default (/etc/xdg) is Akane.
    auto config = KSharedConfig::openConfig(QStringLiteral("kdeglobals"));
    config->reparseConfiguration();
    const QString lnf = config->group(QStringLiteral("KDE")).readEntry("LookAndFeelPackage", QString());
    QString current = QStringLiteral("other");
    for (const auto &[edition, id] : s_editions) {
        if (lnf == id) {
            current = edition;
        }
    }
    if (current != m_current) {
        m_current = current;
        Q_EMIT currentEditionChanged();
    }
    setSelectedEdition(m_current == QLatin1String("other") ? QStringLiteral("akane") : m_current);
    setApplySddm(false);
    setApplyPlymouth(false);
    updateNeedsSave();
}

void UzunyxEditionsKcm::defaults()
{
    setSelectedEdition(QStringLiteral("akane"));
    setApplyTheme(true);
    setApplyWallpaper(true);
    setApplyLock(true);
    setApplyLauncher(true);
    setApplySddm(false);
    setApplyPlymouth(false);
}

void UzunyxEditionsKcm::save()
{
    const QString program = QStandardPaths::findExecutable(QStringLiteral("uzunyx-edition"));
    if (program.isEmpty()) {
        setError(i18n("The uzunyx-edition command was not found."));
        return;
    }
    QStringList args{QStringLiteral("set"), m_selected};
    if (!m_theme) {
        args << QStringLiteral("--no-theme");
    }
    if (!m_wallpaper) {
        args << QStringLiteral("--no-wallpaper");
    }
    if (!m_lock) {
        args << QStringLiteral("--no-lock");
    }
    if (!m_launcher) {
        args << QStringLiteral("--no-launcher");
    }
    if (m_sddm) {
        args << QStringLiteral("--sddm");
    }
    if (m_plymouth && plymouthAvailable()) {
        args << QStringLiteral("--plymouth");
    }

    setError(QString());
    setBusy(true);
    auto process = new QProcess(this);
    m_process = process;
    process->setProcessChannelMode(QProcess::MergedChannels);
    connect(process, &QProcess::finished, this, [this, process](int exitCode, QProcess::ExitStatus status) {
        if (status != QProcess::NormalExit || exitCode != 0) {
            const QString output = QString::fromLocal8Bit(process->readAll()).trimmed();
            setError(output.isEmpty() ? i18n("Could not apply the edition.") : output);
        }
        process->deleteLater();
        m_process = nullptr;
        setBusy(false);
        load();
    });
    process->start(program, args);
}

QUrl UzunyxEditionsKcm::wallpaperPreview(const QString &package) const
{
    const QString dir = QStandardPaths::locate(QStandardPaths::GenericDataLocation,
                                               QStringLiteral("wallpapers/%1/contents/images").arg(package),
                                               QStandardPaths::LocateDirectory);
    if (dir.isEmpty()) {
        return {};
    }
    const QStringList images = QDir(dir).entryList(QDir::Files, QDir::Name);
    return images.isEmpty() ? QUrl() : QUrl::fromLocalFile(QDir(dir).filePath(images.first()));
}

void UzunyxEditionsKcm::setSelectedEdition(const QString &edition)
{
    if (edition == m_selected) {
        return;
    }
    m_selected = edition;
    Q_EMIT selectedEditionChanged();
    updateNeedsSave();
}

void UzunyxEditionsKcm::setOption(bool &option, bool on)
{
    if (option == on) {
        return;
    }
    option = on;
    Q_EMIT optionsChanged();
    updateNeedsSave();
}

void UzunyxEditionsKcm::setApplyTheme(bool on)
{
    setOption(m_theme, on);
}

void UzunyxEditionsKcm::setApplyWallpaper(bool on)
{
    setOption(m_wallpaper, on);
}

void UzunyxEditionsKcm::setApplyLock(bool on)
{
    setOption(m_lock, on);
}

void UzunyxEditionsKcm::setApplyLauncher(bool on)
{
    setOption(m_launcher, on);
}

void UzunyxEditionsKcm::setApplySddm(bool on)
{
    setOption(m_sddm, on);
}

void UzunyxEditionsKcm::setApplyPlymouth(bool on)
{
    setOption(m_plymouth, on);
}

bool UzunyxEditionsKcm::plymouthAvailable() const
{
    return QFileInfo::exists(QStringLiteral("/usr/share/plymouth/themes/uzunyx-akane/uzunyx-akane.plymouth"));
}

void UzunyxEditionsKcm::updateNeedsSave()
{
    // Another edition, or the login or boot screen (not tracked: always
    // offered).
    const bool system = m_sddm || (m_plymouth && plymouthAvailable());
    const bool anything = m_theme || m_wallpaper || m_lock || m_launcher || system;
    setNeedsSave(anything && (m_selected != m_current || system));
}

void UzunyxEditionsKcm::setBusy(bool busy)
{
    if (busy != m_busy) {
        m_busy = busy;
        Q_EMIT busyChanged();
    }
}

void UzunyxEditionsKcm::setError(const QString &error)
{
    if (error != m_error) {
        m_error = error;
        Q_EMIT errorTextChanged();
    }
}

#include "kcm.moc"
