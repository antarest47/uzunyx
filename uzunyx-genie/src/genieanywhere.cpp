/*
    Genie Anywhere — efecto de lámpara mágica para KWin 6 con destino libre.

    Basado en el efecto Magic Lamp de KWin:
    SPDX-FileCopyrightText: 2008 Martin Gräßlin <mgraesslin@kde.org>
    (a su vez basado en la animación de minimizar de Rivo Laks <rivolaks@hot.ee>)

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "genieanywhere.h"

#include <effect/effecthandler.h>

#include <KConfigGroup>
#include <KGlobalAccel>
#include <KSharedConfig>

#include <QAction>
#include <QPointer>
#include <QRegularExpression>
#include <QTimer>

using namespace std::chrono_literals;

namespace KWin
{

static const QString s_configGroup = QStringLiteral("Effect-genieanywhere");

GenieAnywhereEffect::GenieAnywhereEffect()
{
    reconfigure(ReconfigureAll);

    connect(effects, &EffectsHandler::windowAdded, this, &GenieAnywhereEffect::slotWindowOpened);
    connect(effects, &EffectsHandler::windowClosed, this, &GenieAnywhereEffect::slotWindowClosed);
    connect(effects, &EffectsHandler::windowDeleted, this, &GenieAnywhereEffect::slotWindowDeleted);

    const auto windows = effects->stackingOrder();
    for (EffectWindow *window : windows) {
        slotWindowAdded(window);
    }

    setVertexSnappingMode(RenderGeometry::VertexSnappingMode::None);

    // Uzunyx: this replaces KWin's minimize animations while it's loaded.
    // They stay enabled in the configuration, so if this effect doesn't load
    // (e.g. after a KWin update, until it's rebuilt) the Magic Lamp is back
    // instead of no animation at all. Deferred: they may load after this one.
    QTimer::singleShot(0, this, []() {
        for (const QString &name : {QStringLiteral("magiclamp"), QStringLiteral("squash")}) {
            if (effects->isEffectLoaded(name)) {
                effects->unloadEffect(name);
            }
        }
    });

    // --- Atajos globales (se pueden cambiar en Preferencias > Atajos > KWin) ---
    auto addAction = [this](const QString &name, const QString &text, const QKeySequence &seq, auto slot) {
        QAction *a = new QAction(this);
        a->setObjectName(name);
        a->setText(text);
        KGlobalAccel::self()->setDefaultShortcut(a, {seq});
        KGlobalAccel::self()->setShortcut(a, {seq});
        connect(a, &QAction::triggered, this, slot);
    };
    addAction(QStringLiteral("GenieAnywherePickApp"),
              QStringLiteral("Genie Anywhere: elegir destino para la app activa"),
              QKeySequence(Qt::META | Qt::CTRL | Qt::Key_L),
              &GenieAnywhereEffect::pickTargetForActiveApp);
    addAction(QStringLiteral("GenieAnywherePickDefault"),
              QStringLiteral("Genie Anywhere: elegir destino global"),
              QKeySequence(Qt::META | Qt::CTRL | Qt::SHIFT | Qt::Key_L),
              &GenieAnywhereEffect::pickDefaultTarget);
    addAction(QStringLiteral("GenieAnywhereClearApp"),
              QStringLiteral("Genie Anywhere: quitar destino de la app activa"),
              QKeySequence(Qt::META | Qt::CTRL | Qt::ALT | Qt::Key_L),
              &GenieAnywhereEffect::clearTargetForActiveApp);
    addAction(QStringLiteral("GenieAnywhereClearDefault"),
              QStringLiteral("Genie Anywhere: quitar destino global"),
              QKeySequence(),
              &GenieAnywhereEffect::clearDefaultTarget);
    addAction(QStringLiteral("GenieAnywhereToggleOpenClose"),
              QStringLiteral("Genie Anywhere: animar apertura/cierre de la ventana activa"),
              QKeySequence(),
              &GenieAnywhereEffect::toggleOpenCloseForActive);
}

GenieAnywhereEffect::~GenieAnywhereEffect()
{
    for (auto it = m_animations.cbegin(); it != m_animations.cend(); ++it) {
        effects->setElevatedWindow(it.key(), false);
    }
}

bool GenieAnywhereEffect::supported()
{
    return OffscreenEffect::supported() && effects->animationsSupported();
}

void GenieAnywhereEffect::reconfigure(ReconfigureFlags)
{
    effects->config()->reparseConfiguration();
    const KConfigGroup cg = effects->config()->group(s_configGroup);

    const int ms = cg.readEntry("AnimationDuration", 0);
    const std::chrono::milliseconds d = ms > 0 ? std::chrono::milliseconds(ms) : 450ms;
    m_duration = animationTime(d);

    m_defaultOverridesTaskbar = cg.readEntry("DefaultOverridesTaskbar", true);
    m_targetSize = qBound(1, cg.readEntry("TargetSize", 32), 512);

    loadTargets();
}

// ---------------------------------------------------------------------------
// Persistencia de destinos en kwinrc:
//
//   [Effect-genieanywhere]
//   DefaultTarget=x,y,w,h
//
//   [Effect-genieanywhere][Targets]
//   org.kde.dolphin=x,y,w,h
// ---------------------------------------------------------------------------

static QRect parseRect(const QString &s)
{
    const QStringList p = s.split(QLatin1Char(','));
    if (p.size() != 4) {
        return QRect();
    }
    bool ok[4];
    const QRect r(p[0].trimmed().toInt(&ok[0]), p[1].trimmed().toInt(&ok[1]),
                  p[2].trimmed().toInt(&ok[2]), p[3].trimmed().toInt(&ok[3]));
    return (ok[0] && ok[1] && ok[2] && ok[3]) ? r : QRect();
}

static QString rectToString(const QRect &r)
{
    return QStringLiteral("%1,%2,%3,%4").arg(r.x()).arg(r.y()).arg(r.width()).arg(r.height());
}

void GenieAnywhereEffect::loadTargets()
{
    const KConfigGroup cg = effects->config()->group(s_configGroup);
    m_defaultTarget = parseRect(cg.readEntry("DefaultTarget", QString()));

    m_openCloseRules.clear();
    // Uzunyx: Tsunyx Launcher's "magic lamp" mode titles its window like this.
    m_openCloseRules.insert(QStringLiteral("Tsunyx Launcher (lamp)"), QStringLiteral("org.kde.plasmashell"));
    const KConfigGroup openClose = cg.group(QStringLiteral("OpenClose"));
    const QStringList captions = openClose.keyList();
    for (const QString &caption : captions) {
        m_openCloseRules.insert(caption, openClose.readEntry(caption, QString()).trimmed());
    }

    m_appTargets.clear();
    const KConfigGroup targets = cg.group(QStringLiteral("Targets"));
    const QStringList keys = targets.keyList();
    for (const QString &key : keys) {
        const QRect r = parseRect(targets.readEntry(key, QString()));
        if (r.isValid()) {
            m_appTargets.insert(key, r);
        }
    }
}

void GenieAnywhereEffect::saveTargets()
{
    KConfigGroup cg = effects->config()->group(s_configGroup);
    if (m_defaultTarget.isValid()) {
        cg.writeEntry("DefaultTarget", rectToString(m_defaultTarget));
    } else {
        cg.deleteEntry("DefaultTarget");
    }

    KConfigGroup targets = cg.group(QStringLiteral("Targets"));
    targets.deleteGroup();
    targets = cg.group(QStringLiteral("Targets"));
    for (auto it = m_appTargets.cbegin(); it != m_appTargets.cend(); ++it) {
        targets.writeEntry(it.key(), rectToString(it.value()));
    }

    KConfigGroup openClose = cg.group(QStringLiteral("OpenClose"));
    openClose.deleteGroup();
    openClose = cg.group(QStringLiteral("OpenClose"));
    for (auto it = m_openCloseRules.cbegin(); it != m_openCloseRules.cend(); ++it) {
        openClose.writeEntry(it.key(), it.value());
    }
    cg.sync();
}

// ---------------------------------------------------------------------------
// Selección interactiva
// ---------------------------------------------------------------------------

QString GenieAnywhereEffect::resourceClass(EffectWindow *w)
{
    // windowClass() devuelve "resourceName resourceClass"; usamos la clase.
    const QString cls = w->windowClass().section(QLatin1Char(' '), -1).trimmed();
    return cls.isEmpty() ? w->windowClass().trimmed() : cls;
}

QString GenieAnywhereEffect::appKey(EffectWindow *w)
{
    const QString cls = resourceClass(w);
    // Todas las ventanas de Plasma comparten clase (paneles, popups, menús
    // como Tsunyx…), así que para ellas la regla va por clase + título.
    if (cls.contains(QLatin1String("plasmashell"))) {
        return cls + QLatin1Char('/') + w->caption();
    }
    return cls;
}

bool GenieAnywhereEffect::usesOpenClose(EffectWindow *w) const
{
    if (m_openCloseRules.isEmpty() || w->isDock() || w->isDesktop()) {
        return false;
    }
    const QString caption = w->caption();
    const QString cls = resourceClass(w);
    for (auto it = m_openCloseRules.cbegin(); it != m_openCloseRules.cend(); ++it) {
        if (!it.key().isEmpty() && caption.contains(it.key())
            && (it.value().isEmpty() || it.value() == cls)) {
            return true;
        }
    }
    return false;
}

// Ventana a la que se le asigna el destino con el atajo: la activa o, si no
// hay (los menús de Plasma a veces no toman foco), el último menú abierto.
EffectWindow *GenieAnywhereEffect::pickSubject() const
{
    EffectWindow *w = effects->activeWindow();
    if (w && !w->isDesktop() && !w->isDock()) {
        return w;
    }
    if (m_lastOpenCloseWindow && !m_lastOpenCloseWindow->isDeleted()) {
        return m_lastOpenCloseWindow.data();
    }
    return nullptr;
}

QRect GenieAnywhereEffect::targetRectAt(const QPointF &point) const
{
    const QPoint p = point.toPoint();
    QRect r(0, 0, m_targetSize, m_targetSize);
    r.moveCenter(p);

    // Si se hizo clic sobre un panel, mantenemos el destino dentro de él
    // para que la detección de orientación funcione bien.
    const auto stackingOrder = effects->stackingOrder();
    for (EffectWindow *window : stackingOrder) {
        if (!window->isDock()) {
            continue;
        }
        const QRect panel = window->frameGeometry().toRect();
        if (!panel.contains(p)) {
            continue;
        }
        if (r.width() > panel.width()) {
            r.setWidth(panel.width());
        }
        if (r.height() > panel.height()) {
            r.setHeight(panel.height());
        }
        r.moveCenter(p);
        if (r.left() < panel.left()) {
            r.moveLeft(panel.left());
        }
        if (r.right() > panel.right()) {
            r.moveRight(panel.right());
        }
        if (r.top() < panel.top()) {
            r.moveTop(panel.top());
        }
        if (r.bottom() > panel.bottom()) {
            r.moveBottom(panel.bottom());
        }
        break;
    }
    return r;
}

void GenieAnywhereEffect::flashMessage(const QString &text, const QString &icon)
{
    effects->showOnScreenMessage(text, icon);
    QTimer::singleShot(1600, this, []() {
        effects->hideOnScreenMessage();
    });
}

void GenieAnywhereEffect::startPicking(const QString &key, const QString &label)
{
    if (m_picking) {
        return;
    }
    m_picking = true;

    effects->showOnScreenMessage(
        QStringLiteral("Hacé clic en el ítem del panel donde debe entrar %1 (Esc para cancelar)").arg(label),
        QStringLiteral("crosshairs"));

    QPointer<GenieAnywhereEffect> self(this);
    effects->startInteractivePositionSelection([self, key, label](const QPointF &pos) {
        effects->hideOnScreenMessage(EffectsHandler::OnScreenMessageHideFlag::SkipsCloseAnimation);
        if (!self) {
            return;
        }
        self->m_picking = false;

        if (pos.x() < 0 && pos.y() < 0) { // (-1,-1) = cancelado
            return;
        }

        const QRect target = self->targetRectAt(pos);
        if (key.isEmpty()) {
            self->m_defaultTarget = target;
        } else {
            self->m_appTargets.insert(key, target);
        }
        self->saveTargets();
        self->flashMessage(QStringLiteral("Destino guardado para %1").arg(label), QStringLiteral("dialog-ok"));
    });
}

void GenieAnywhereEffect::pickTargetForActiveApp()
{
    EffectWindow *w = pickSubject();
    if (!w) {
        flashMessage(QStringLiteral("No hay una ventana activa"), QStringLiteral("dialog-warning"));
        return;
    }
    const QString key = appKey(w);
    startPicking(key, key);
}

void GenieAnywhereEffect::pickDefaultTarget()
{
    startPicking(QString(), QStringLiteral("todas las ventanas"));
}

void GenieAnywhereEffect::clearTargetForActiveApp()
{
    EffectWindow *w = pickSubject();
    if (!w) {
        return;
    }
    const QString key = appKey(w);
    if (m_appTargets.remove(key)) {
        saveTargets();
        flashMessage(QStringLiteral("Destino quitado para %1").arg(key), QStringLiteral("edit-clear"));
    } else {
        flashMessage(QStringLiteral("%1 no tenía destino propio").arg(key), QStringLiteral("dialog-information"));
    }
}

void GenieAnywhereEffect::toggleOpenCloseForActive()
{
    EffectWindow *w = pickSubject();
    if (!w || w->caption().isEmpty()) {
        flashMessage(QStringLiteral("No hay una ventana activa con título"), QStringLiteral("dialog-warning"));
        return;
    }
    const QString caption = w->caption();
    if (m_openCloseRules.remove(caption)) {
        flashMessage(QStringLiteral("\"%1\" ya no se anima al abrir/cerrar").arg(caption), QStringLiteral("edit-clear"));
    } else {
        m_openCloseRules.insert(caption, resourceClass(w));
        flashMessage(QStringLiteral("\"%1\" se anima al abrir/cerrar").arg(caption), QStringLiteral("dialog-ok"));
    }
    saveTargets();
}

void GenieAnywhereEffect::clearDefaultTarget()
{
    m_defaultTarget = QRect();
    saveTargets();
    flashMessage(QStringLiteral("Destino global quitado"), QStringLiteral("edit-clear"));
}

// ---------------------------------------------------------------------------
// Resolución del destino y la dirección de la animación
// ---------------------------------------------------------------------------

QRect GenieAnywhereEffect::resolveTarget(EffectWindow *w) const
{
    // A window with an open/close rule may say where its lamp is: a title
    // ending in "x,y", a point in the window's coordinates. Tsunyx does it
    // with its panel button, which KWin can't see inside the panel.
    if (usesOpenClose(w)) {
        static const QRegularExpression point(QStringLiteral(" (-?\\d+),(-?\\d+)$"));
        const QRegularExpressionMatch match = point.match(w->caption());
        if (match.hasMatch()) {
            const QPointF local(match.captured(1).toInt(), match.captured(2).toInt());
            if (!local.isNull()) {
                const RectF frame = w->frameGeometry();
                return targetRectAt(QPointF(frame.x() + local.x(), frame.y() + local.y()));
            }
        }
    }

    const auto it = m_appTargets.constFind(appKey(w));
    if (it != m_appTargets.constEnd()) {
        return it.value();
    }

    // Menús/ventanas con apertura animada: si no tienen destino propio,
    // salen desde donde estaba el cursor al abrirse (el botón que los lanzó).
    const auto origin = m_openOrigins.constFind(w);
    if (origin != m_openOrigins.constEnd()) {
        return origin.value();
    }

    const QRect icon = w->iconGeometry().toRect();
    if (m_defaultTarget.isValid() && (m_defaultOverridesTaskbar || !icon.isValid())) {
        return m_defaultTarget;
    }
    return icon; // puede ser inválido: se usa el cursor como último recurso
}

GenieAnywhereEffect::IconPosition GenieAnywhereEffect::resolvePosition(EffectWindow *w, const QRect &geo, QRect &icon) const
{
    Q_UNUSED(w)
    IconPosition position = Top;

    // Destino que cae dentro de la ventana (o no hay destino): se usa el
    // borde más cercano, como hace Magic Lamp con el cursor.
    auto nearestEdge = [&](QPoint pt) {
        const QRect extG = geo;
        const int d[2][2] = {{pt.x() - extG.x(), extG.right() - pt.x()},
                             {pt.y() - extG.y(), extG.bottom() - pt.y()}};
        int di = d[1][0];
        position = Top;
        if (d[0][0] < di) {
            di = d[0][0];
            position = Left;
        }
        if (d[1][1] < di) {
            di = d[1][1];
            position = Bottom;
        }
        if (d[0][1] < di) {
            position = Right;
        }
        switch (position) {
        case Top:
            pt.setY(extG.y());
            break;
        case Left:
            pt.setX(extG.x());
            break;
        case Bottom:
            pt.setY(extG.bottom());
            break;
        case Right:
            pt.setX(extG.right());
            break;
        }
        icon = QRect(pt, QSize(0, 0));
    };

    if (!icon.isValid()) {
        const QPoint pt = cursorPos().toPoint();
        if (geo.contains(pt)) {
            nearestEdge(pt);
        } else {
            if (pt.y() < geo.y()) {
                position = Top;
            } else if (pt.x() < geo.x()) {
                position = Left;
            } else if (pt.y() > geo.bottom()) {
                position = Bottom;
            } else if (pt.x() > geo.right()) {
                position = Right;
            }
            icon = QRect(pt, QSize(0, 0));
        }
        return position;
    }

    // ¿El destino está en un panel?
    EffectWindow *panel = nullptr;
    const auto stackingOrder = effects->stackingOrder();
    for (EffectWindow *window : stackingOrder) {
        if (window->isDock() && window->frameGeometry().intersects(icon)) {
            panel = window;
            break;
        }
    }

    if (panel) {
        // A diferencia de Magic Lamp, comparamos con la pantalla del panel,
        // así funciona también si el destino está en otro monitor.
        const QRectF panelScreen = effects->clientArea(ScreenArea, panel);
        if (panel->width() >= panel->height()) {
            position = icon.center().y() <= panelScreen.center().y() ? Top : Bottom;
        } else {
            position = icon.center().x() <= panelScreen.center().x() ? Left : Right;
        }

        if (panel->isHidden()) {
            switch (position) {
            case Bottom:
                icon.moveTop(panelScreen.y() + panelScreen.height());
                break;
            case Top:
                icon.moveTop(panelScreen.y() - icon.height());
                break;
            case Left:
                icon.moveLeft(panelScreen.x() - icon.width());
                break;
            case Right:
                icon.moveLeft(panelScreen.x() + panelScreen.width());
                break;
            }
        }

        // Si la ventana tapa el panel, la dirección elegida no tiene sentido:
        // usamos la posición relativa a la ventana.
        const bool coherent = (position == Bottom && icon.top() >= geo.top())
            || (position == Top && icon.bottom() <= geo.bottom())
            || (position == Left && icon.right() <= geo.right())
            || (position == Right && icon.left() >= geo.left());
        if (coherent) {
            return position;
        }
    }

    // Destino libre (fuera de un panel): dirección según dónde está respecto de la ventana.
    const QPoint c = icon.center();
    if (geo.contains(c)) {
        nearestEdge(c);
        return position;
    }
    const int below = icon.top() - geo.bottom();
    const int above = geo.top() - icon.bottom();
    const int left = geo.left() - icon.right();
    const int right = icon.left() - geo.right();
    int best = below;
    position = Bottom;
    if (above > best) {
        best = above;
        position = Top;
    }
    if (left > best) {
        best = left;
        position = Left;
    }
    if (right > best) {
        position = Right;
    }
    return position;
}

// ---------------------------------------------------------------------------
// Animación
// ---------------------------------------------------------------------------

void GenieAnywhereEffect::prePaintScreen(ScreenPrePaintData &data)
{
    data.mask |= PAINT_SCREEN_WITH_TRANSFORMED_WINDOWS;
    effects->prePaintScreen(data);
}

void GenieAnywhereEffect::prePaintWindow(RenderView *view, EffectWindow *w, WindowPrePaintData &data)
{
    auto animationIt = m_animations.find(w);
    if (animationIt != m_animations.end()) {
        (*animationIt).timeLine.advance(view);
        data.setTransformed();
    }
    effects->prePaintWindow(view, w, data);
}

// Smootherstep: 0 -> 1 with zero slope at both ends.
static qreal smoother(qreal t)
{
    t = std::clamp(t, 0.0, 1.0);
    return t * t * t * (t * (t * 6 - 15) + 10);
}

// Genie like macOS, in two phases (unlike KWin's Magic Lamp, where every row
// falls along one cubic curve and the sides come out concave):
//  1. funnel (first s_funnelPart of the way): the near end of the window
//     stretches to the target and narrows to its width, while the far edge
//     stays put; the sides take a soft S shape (smootherstep);
//  2. pour: the whole window slides down that funnel into the target,
//     squeezed there.
// Worked out in a frame where the window travels along +t towards the
// target, so the same code serves the four directions.
static constexpr qreal s_funnelPart = 0.4;

void GenieAnywhereEffect::apply(EffectWindow *w, int mask, WindowPaintData &data, WindowQuadList &quads)
{
    Q_UNUSED(mask)
    Q_UNUSED(data)
    auto animationIt = m_animations.constFind(w);
    if (animationIt == m_animations.constEnd()) {
        return;
    }

    // 0 = in place, 1 = fully in the target
    const qreal progress = (*animationIt).timeLine.value();

    const QRect geo = w->frameGeometry().toRect();
    QRect icon = resolveTarget(w);
    const IconPosition position = resolvePosition(w, geo, icon);

    // Travel axis t (towards the target) and cross axis c, in screen space.
    const bool vertical = position == Top || position == Bottom;
    const qreal sign = (position == Bottom || position == Right) ? 1 : -1;
    auto travel = [&](qreal x, qreal y) {
        return sign * (vertical ? y : x);
    };
    auto cross = [&](qreal x, qreal y) {
        return vertical ? x : y;
    };
    const qreal geoT0 = travel(geo.x(), geo.y());
    const qreal geoT1 = travel(geo.x() + geo.width(), geo.y() + geo.height());
    const qreal far = std::min(geoT0, geoT1);
    const qreal near = std::max(geoT0, geoT1);
    const qreal iconT0 = travel(icon.x(), icon.y());
    const qreal iconT1 = travel(icon.x() + icon.width(), icon.y() + icon.height());
    const qreal target = std::min(iconT0, iconT1);
    const qreal targetEnd = std::max(iconT0, iconT1);
    const qreal winC0 = vertical ? geo.x() : geo.y();
    const qreal winC1 = winC0 + (vertical ? geo.width() : geo.height());
    const qreal iconC0 = vertical ? icon.x() : icon.y();
    const qreal iconC1 = iconC0 + (vertical ? icon.width() : icon.height());
    const qreal length = std::max(1.0, near - far);
    const qreal reach = std::max(1.0, target - far);

    const qreal funnel = smoother(progress / s_funnelPart);
    const qreal pour = smoother((progress - s_funnelPart) / (1 - s_funnelPart));
    const qreal stretchedNear = near + (target - near) * funnel;

    auto deform = [&](WindowVertex &vertex) {
        const qreal sx = geo.x() + vertex.x();
        const qreal sy = geo.y() + vertex.y();
        const qreal v = std::clamp((travel(sx, sy) - far) / length, 0.0, 1.0);
        const qreal c = cross(sx, sy);

        qreal t = far + v * (stretchedNear - far) + pour * (target - far);
        t = std::min(t, targetEnd);
        const qreal bend = smoother((t - far) / reach) * funnel;
        const qreal lo = winC0 + (iconC0 - winC0) * bend;
        const qreal hi = winC1 + (iconC1 - winC1) * bend;
        const qreal nc = lo + (c - winC0) / std::max(1.0, winC1 - winC0) * (hi - lo);

        const qreal screenT = sign * t;
        const qreal nx = vertical ? nc : screenT;
        const qreal ny = vertical ? screenT : nc;
        vertex.setX(nx - geo.x());
        vertex.setY(ny - geo.y());
    };

    quads = quads.makeGrid(40);
    for (WindowQuad &quad : quads) {
        for (int i = 0; i < 4; ++i) {
            deform(quad[i]);
        }
    }
}

void GenieAnywhereEffect::postPaintScreen()
{
    auto animationIt = m_animations.begin();
    while (animationIt != m_animations.end()) {
        if ((*animationIt).timeLine.done()) {
            effects->setElevatedWindow(animationIt.key(), false);
            unredirect(animationIt.key());
            animationIt = m_animations.erase(animationIt);
        } else {
            ++animationIt;
        }
    }

    effects->addRepaintFull();
    effects->postPaintScreen();
}

void GenieAnywhereEffect::slotWindowAdded(EffectWindow *w)
{
    connect(w, &EffectWindow::minimizedChanged, this, [this, w]() {
        if (w->isMinimized()) {
            slotWindowMinimized(w);
        } else {
            slotWindowUnminimized(w);
        }
    });
}

// Al minimizar o cerrar, KWin activa otra ventana y la sube: la animación,
// dibujada en el lugar de la ventana en la pila, quedaba tapada (pasa también
// con Magic Lamp). Mientras dura, la ventana se dibuja encima de todo.
void GenieAnywhereEffect::startAnimating(EffectWindow *w)
{
    effects->setElevatedWindow(w, true);
    redirect(w);
    effects->addRepaintFull();
}

void GenieAnywhereEffect::slotWindowDeleted(EffectWindow *w)
{
    if (m_animations.remove(w)) {
        effects->setElevatedWindow(w, false);
    }
    m_openOrigins.remove(w);
}

void GenieAnywhereEffect::slotWindowOpened(EffectWindow *w)
{
    slotWindowAdded(w);

    if (effects->activeFullScreenEffect() || !usesOpenClose(w)) {
        return;
    }

    m_lastOpenCloseWindow = w;
    QRect origin(0, 0, m_targetSize, m_targetSize);
    origin.moveCenter(cursorPos().toPoint());
    m_openOrigins.insert(w, origin);

    GenieAnimation &animation = m_animations[w];
    animation.timeLine.reset();
    animation.timeLine.setDirection(TimeLine::Backward); // 1 -> 0: sale de la lámpara
    animation.timeLine.setDuration(m_duration);
    animation.timeLine.setEasingCurve(QEasingCurve::Linear);

    // Reclamamos la animación de apertura para que Desvanecer/Escala no la dupliquen.
    w->setData(WindowAddedGrabRole, QVariant::fromValue(static_cast<void *>(this)));

    startAnimating(w);
}

void GenieAnywhereEffect::slotWindowClosed(EffectWindow *w)
{
    if (effects->activeFullScreenEffect() || w->skipsCloseAnimation()) {
        return;
    }
    if (!usesOpenClose(w) && !m_openOrigins.contains(w)) {
        return;
    }

    GenieAnimation &animation = m_animations[w];
    if (animation.timeLine.running()) {
        // Se cerró mientras se abría: damos la vuelta desde donde está.
        animation.timeLine.toggleDirection();
    } else {
        animation.timeLine.reset();
        animation.timeLine.setDirection(TimeLine::Forward); // 0 -> 1: vuelve a la lámpara
        animation.timeLine.setDuration(m_duration);
        animation.timeLine.setEasingCurve(QEasingCurve::Linear);
    }
    animation.deletedRef = EffectWindowDeletedRef(w);

    w->setData(WindowClosedGrabRole, QVariant::fromValue(static_cast<void *>(this)));

    startAnimating(w);
}

void GenieAnywhereEffect::slotWindowMinimized(EffectWindow *w)
{
    if (effects->activeFullScreenEffect()) {
        return;
    }

    GenieAnimation &animation = m_animations[w];
    if (animation.timeLine.running()) {
        animation.timeLine.toggleDirection();
    } else {
        animation.visibleRef = EffectWindowVisibleRef(w, EffectWindow::PAINT_DISABLED_BY_MINIMIZE);
        animation.timeLine.setDirection(TimeLine::Forward);
        animation.timeLine.setDuration(m_duration);
        animation.timeLine.setEasingCurve(QEasingCurve::Linear);
    }

    startAnimating(w);
}

void GenieAnywhereEffect::slotWindowUnminimized(EffectWindow *w)
{
    if (effects->activeFullScreenEffect()) {
        return;
    }

    GenieAnimation &animation = m_animations[w];
    if (animation.timeLine.running()) {
        animation.timeLine.toggleDirection();
    } else {
        animation.visibleRef = EffectWindowVisibleRef(w, EffectWindow::PAINT_DISABLED_BY_MINIMIZE);
        animation.timeLine.setDirection(TimeLine::Backward);
        animation.timeLine.setDuration(m_duration);
        animation.timeLine.setEasingCurve(QEasingCurve::Linear);
    }

    startAnimating(w);
}

bool GenieAnywhereEffect::isActive() const
{
    return !m_animations.isEmpty();
}

} // namespace KWin

#include "moc_genieanywhere.cpp"
