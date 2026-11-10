/*
    Genie Anywhere — efecto de lámpara mágica para KWin 6 con destino libre.

    Basado en el efecto Magic Lamp de KWin:
    SPDX-FileCopyrightText: 2008 Martin Gräßlin <mgraesslin@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <effect/effectwindow.h>
#include <effect/offscreeneffect.h>
#include <effect/timeline.h>

#include <QHash>
#include <QPointer>
#include <QRect>

class QAction;

namespace KWin
{

struct GenieAnimation
{
    EffectWindowVisibleRef visibleRef; // minimizar: sigue dibujando la ventana minimizada
    EffectWindowDeletedRef deletedRef; // cerrar: sigue dibujando la ventana cerrada
    TimeLine timeLine;
};

class GenieAnywhereEffect : public OffscreenEffect
{
    Q_OBJECT

public:
    GenieAnywhereEffect();
    ~GenieAnywhereEffect() override;

    void reconfigure(ReconfigureFlags) override;
    void prePaintScreen(ScreenPrePaintData &data) override;
    void prePaintWindow(RenderView *view, EffectWindow *w, WindowPrePaintData &data) override;
    void postPaintScreen() override;
    bool isActive() const override;

    int requestedEffectChainPosition() const override
    {
        return 50;
    }

    static bool supported();

protected:
    void apply(EffectWindow *window, int mask, WindowPaintData &data, WindowQuadList &quads) override;

private Q_SLOTS:
    void slotWindowAdded(KWin::EffectWindow *w);
    void slotWindowOpened(KWin::EffectWindow *w);
    void slotWindowClosed(KWin::EffectWindow *w);
    void slotWindowDeleted(KWin::EffectWindow *w);
    void slotWindowMinimized(KWin::EffectWindow *w);
    void slotWindowUnminimized(KWin::EffectWindow *w);

    void pickTargetForActiveApp();
    void pickDefaultTarget();
    void clearTargetForActiveApp();
    void clearDefaultTarget();
    void toggleOpenCloseForActive();

private:
    enum IconPosition {
        Top,
        Bottom,
        Left,
        Right
    };

    // Rectángulo destino para una ventana (regla por app > destino global > icono de la barra de tareas).
    QRect resolveTarget(EffectWindow *w) const;
    // Decide hacia qué lado "se chupa" la ventana; puede mover el destino (panel oculto, destino dentro de la ventana).
    IconPosition resolvePosition(EffectWindow *w, const QRect &geo, QRect &icon) const;

    QRect targetRectAt(const QPointF &point) const;
    static QString appKey(EffectWindow *w);
    static QString resourceClass(EffectWindow *w);
    bool usesOpenClose(EffectWindow *w) const;
    EffectWindow *pickSubject() const;
    void startPicking(const QString &key, const QString &label);
    void flashMessage(const QString &text, const QString &icon = QString());
    void startAnimating(EffectWindow *w);

    void loadTargets();
    void saveTargets();

    std::chrono::milliseconds m_duration;
    QHash<EffectWindow *, GenieAnimation> m_animations;

    QHash<QString, QRect> m_appTargets; // clave = clase de la ventana (resourceClass)
    QRect m_defaultTarget;              // inválido = sin destino global
    bool m_defaultOverridesTaskbar = true;
    int m_targetSize = 32;
    bool m_picking = false;

    // Ventanas que se animan al abrir/cerrar: título (o parte) -> clase (vacío = cualquiera)
    QHash<QString, QString> m_openCloseRules;
    // Dónde estaba el cursor al abrirse cada ventana (destino por defecto para abrir/cerrar)
    QHash<EffectWindow *, QRect> m_openOrigins;
    QPointer<EffectWindow> m_lastOpenCloseWindow;
};

} // namespace KWin
