/*
    Uzunyx's logout screen, from Breeze's. Its buttons are like the window
    buttons (LogoutButton.qml), and it can also switch user.

    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.components as PlasmaComponents
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigami as Kirigami

import org.kde.breeze.components
import "timer.js" as AutoTriggerTimer

import org.kde.plasma.private.sessions

Item {
    id: root
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    height: screenGeometry.height
    width: screenGeometry.width

    signal logoutRequested()
    signal haltRequested()
    signal haltUpdateRequested()
    signal suspendRequested(int spdMethod)
    signal rebootRequested()
    signal rebootRequested2(int opt)
    signal rebootUpdateRequested()
    signal cancelRequested()
    signal lockScreenRequested()
    signal cancelSoftwareUpdateRequested()

    function sleepRequested() {
        root.suspendRequested(2);
    }

    function hibernateRequested() {
        root.suspendRequested(4);
    }

    property real timeout: 30
    property real remainingTime: root.timeout

    property var currentAction: {
        switch (sdtype) {
        case ShutdownType.ShutdownTypeReboot:
            return () => softwareUpdatePending ? rebootUpdateRequested() : rebootRequested();
        case ShutdownType.ShutdownTypeHalt:
            return () => softwareUpdatePending ? haltUpdateRequested() : haltRequested();
        default:
            return () => logoutRequested();
        }
    }

    readonly property bool showAllOptions: sdtype === ShutdownType.ShutdownTypeDefault

    KCoreAddons.KUser {
        id: kuser
    }

    SessionManagement {
        id: sessionManagement
    }

    function switchUser() {
        sessionManagement.switchUser();
        root.cancelRequested();
    }

    // The countdown goes around the button of the action that will run.
    function countdownFor(type) {
        return countDownTimer.running && sdtype === type ? root.remainingTime / root.timeout : -1;
    }

    // For showing an "other users are logged in" hint
    SessionsModel {
        id: otherSessionsModel

        // In case the default values ever change
        includeUnusedSessions: false
        includeOwnSession: false
    }

    QQC2.Action {
        onTriggered: root.cancelRequested()
        shortcut: "Escape"
    }

    onRemainingTimeChanged: {
        if (remainingTime <= 0) {
            (currentAction)();
        }
    }

    Timer {
        id: countDownTimer
        running: !showAllOptions
        repeat: true
        interval: 1000
        onTriggered: remainingTime--
        Component.onCompleted: {
            AutoTriggerTimer.addCancelAutoTriggerCallback(function() {
                countDownTimer.running = false;
            });
        }
    }

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        // Intentionally hardcoded because any other color looks terrible here.
        // Any bug reports about illegible text or icons should be considered
        // a color scheme error and sent back to the user or their distro.
        color: "black"
        opacity: 0.85
    }
    MouseArea {
        anchors.fill: parent
        onClicked: root.cancelRequested()
    }
    UserDelegate {
        width: Kirigami.Units.gridUnit * 8
        height: Kirigami.Units.gridUnit * 9
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.verticalCenter
        }
        constrainText: false
        avatarPath: kuser.faceIconUrl
        iconSource: "user-identity"
        isCurrent: true
        name: kuser.fullName
    }
    ColumnLayout {
        id: column

        anchors {
            top: parent.verticalCenter
            topMargin: Kirigami.Units.gridUnit * 2
            horizontalCenter: parent.horizontalCenter
        }
        spacing: Kirigami.Units.largeSpacing

        height: Math.max(implicitHeight, Kirigami.Units.gridUnit * 10)
        width: Math.max(implicitWidth, Kirigami.Units.gridUnit * 16)

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.alignment: Qt.AlignHCenter
            //opacity, as visible would re-layout
            opacity: countDownTimer.running ? 1 : 0
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
            text: {
                switch (sdtype) {
                    case ShutdownType.ShutdownTypeReboot:
                        return softwareUpdatePending ? i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Installing software updates and restarting in 1 second", "Installing software updates and restarting in %1 seconds", root.remainingTime)
                        : i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Restarting in 1 second", "Restarting in %1 seconds", root.remainingTime);
                    case ShutdownType.ShutdownTypeNone:
                        return i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Logging out in 1 second", "Logging out in %1 seconds", root.remainingTime);
                    case ShutdownType.ShutdownTypeHalt:
                    default:
                        return softwareUpdatePending ? i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Installing software updates and shutting down in 1 second", "Installing software updates and shutting down in %1 seconds", root.remainingTime)
                        : i18ndp("plasma_lookandfeel_org.kde.lookandfeel", "Shutting down in 1 second", "Shutting down in %1 seconds", root.remainingTime);
                }
            }
            textFormat: Text.PlainText
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            text: i18ndp("plasma_lookandfeel_org.kde.lookandfeel",
                         "One other user is currently logged in. If the computer is shut down or restarted, that user may lose work.",
                         "%1 other users are currently logged in. If the computer is shut down or restarted, those users may lose work.",
                         otherSessionsModel.count)
            textFormat: Text.PlainText
            visible: otherSessionsModel.count > 0 && (sdtype !== ShutdownType.ShutdownTypeNone || root.showAllOptions)
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            text: {
                if (isUefi) {
                    return i18nd("plasma_lookandfeel_org.kde.lookandfeel", "When restarted, the computer will enter UEFI firmware settings.");
                } else {
                    return i18nd("plasma_lookandfeel_org.kde.lookandfeel", "When restarted, the computer will enter the firmware setup screen.");
                }
            }
            textFormat: Text.PlainText
            visible: rebootToFirmwareSetup
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "When restarted, the computer will enter the boot loader menu.")
            textFormat: Text.PlainText
            visible: rebootToBootLoaderMenu
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "%1 is a boot loader entry", "When restarted, the computer will switch to %1.", rebootToBootLoaderEntry)
            textFormat: Text.PlainText
            visible: rebootToBootLoaderEntry != ""
        }

        Row {
            id: logoutButtonsRow

            Layout.topMargin: Kirigami.Units.gridUnit * 2 - column.spacing
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.smallSpacing

            // Left and right go through the visible buttons, wrapping around.
            function move(step) {
                const buttons = children.filter(b => b.visible);
                const current = buttons.findIndex(b => b.activeFocus);
                buttons[(Math.max(current, 0) + step + buttons.length) % buttons.length].forceActiveFocus();
                AutoTriggerTimer.cancelAutoTrigger();
            }
            Keys.onLeftPressed: move(-1)
            Keys.onRightPressed: move(1)

            LogoutButton {
                id: logoutButton
                iconName: "system-log-out-symbolic"
                text: root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Log Out")
                                          : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Log Out Now")
                countdown: root.countdownFor(ShutdownType.ShutdownTypeNone)
                onClicked: root.logoutRequested()
                focus: sdtype === ShutdownType.ShutdownTypeNone
                visible: canLogout && (sdtype === ShutdownType.ShutdownTypeNone || root.showAllOptions)
            }
            LogoutButton {
                id: switchUserButton
                iconName: "system-switch-user-symbolic"
                text: i18nd("plasma_applet_org.kde.plasma.lock_logout", "Switch user…").replace("…", "")
                onClicked: root.switchUser()
                visible: sessionManagement.canSwitchUser && root.showAllOptions
            }
            LogoutButton {
                id: suspendButton
                iconName: "system-suspend-symbolic"
                text: root.showAllOptions ? i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Suspend to RAM", "Slee&p")
                                          : i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Suspend to RAM", "Slee&p Now")
                onClicked: root.sleepRequested()
                visible: spdMethods.SuspendState && root.showAllOptions
            }
            LogoutButton {
                id: hibernateButton
                // Kora only has it in colour, which would turn into a blob as a mask.
                iconName: "/usr/share/icons/breeze/actions/24/system-suspend-hibernate-symbolic.svg"
                text: root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Hibernate")
                                          : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Hibernate Now")
                onClicked: root.hibernateRequested()
                visible: spdMethods.HibernateState && root.showAllOptions
            }
            LogoutButton {
                id: rebootButton
                iconName: "system-reboot-symbolic"
                text: {
                    if (softwareUpdatePending) {
                        return i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "@action:button Keep short", "Install Updates and Restart")
                    }
                    return root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Restart")
                                               : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Restart Now")
                }
                countdown: root.countdownFor(ShutdownType.ShutdownTypeReboot)
                onClicked: softwareUpdatePending ? root.rebootUpdateRequested() : root.rebootRequested()
                focus: sdtype === ShutdownType.ShutdownTypeReboot
                visible: maysd && (sdtype === ShutdownType.ShutdownTypeReboot || root.showAllOptions)
            }
            LogoutButton {
                id: rebootWithoutUpdatesButton
                iconName: "system-reboot-symbolic"
                text: root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Restart")
                                          : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Restart Now")
                onClicked: root.rebootRequested()
                visible: maysd && softwareUpdatePending && (sdtype === ShutdownType.ShutdownTypeReboot || root.showAllOptions)
            }
            LogoutButton {
                id: shutdownButton
                danger: true
                iconName: "system-shutdown-symbolic"
                text: {
                    if (softwareUpdatePending) {
                        return i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "@action:button Keep short", "Install Updates and Shut Down")
                    }
                    return root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Shut Down")
                                               : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Shut Down Now")
                }
                countdown: root.countdownFor(ShutdownType.ShutdownTypeHalt)
                onClicked: softwareUpdatePending ? root.haltUpdateRequested() : root.haltRequested()
                focus: sdtype === ShutdownType.ShutdownTypeHalt || root.showAllOptions
                visible: maysd && (sdtype === ShutdownType.ShutdownTypeHalt || root.showAllOptions)
            }
            LogoutButton {
                id: shutdownWithoutUpdatesButton
                danger: true
                iconName: "system-shutdown-symbolic"
                text: root.showAllOptions ? i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Shut Down")
                                          : i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Shut Down Now")
                onClicked: root.haltRequested()
                visible: maysd && softwareUpdatePending && (sdtype === ShutdownType.ShutdownTypeHalt || root.showAllOptions)
            }
            LogoutButton {
                id: cancelButton
                iconName: "dialog-cancel-symbolic"
                text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "&Cancel")
                onClicked: root.cancelRequested()
            }
        }
    }
}
