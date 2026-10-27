// SPDX-License-Identifier: GPL-3.0-or-later
//
// OhMyMac — macOS menu bar layout for GNOME Shell 47–51.
//
//   [logo] [App Name ▾] ··········· [status icons] [Tue 27 Oct 14:05]
//
// The focused application gets a bold title with a small menu, the clock
// moves to the right end, notification banners slide in at the top right,
// and the workspace pill is hidden. Every change is
// reverted in disable().

import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
import Shell from 'gi://Shell';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {Extension, gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

const AppMenuButton = GObject.registerClass(
class OhMyMacAppMenuButton extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'OhMyMac App Menu');
        this.add_style_class_name('ohmymac-app-menu');

        this._label = new St.Label({
            style_class: 'ohmymac-app-name',
            y_align: Clutter.ActorAlign.CENTER,
        });
        this.add_child(this._label);

        this._newWindowItem = this.menu.addAction(_('New Window'), () => this._app?.open_new_window(-1));
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._hideItem = this.menu.addAction(_('Hide'), () => this._hideApp());
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._quitItem = this.menu.addAction(_('Quit'), () => this._app?.request_quit());

        this._tracker = Shell.WindowTracker.get_default();
        this._tracker.connectObject('notify::focus-app', () => this._sync(), this);
        Main.overview.connectObject(
            'showing', () => this._sync(),
            'hidden', () => this._sync(),
            this);
        this._sync();
    }

    _hideApp() {
        for (const window of this._app?.get_windows() ?? [])
            window.minimize();
    }

    _sync() {
        this._app = Main.overview.visible ? null : this._tracker.focus_app;
        if (!this._app) {
            this.hide();
            return;
        }
        const name = this._app.get_name();
        this._label.text = name;
        this._hideItem.label.text = _('Hide %s').format(name);
        this._quitItem.label.text = _('Quit %s').format(name);
        this._newWindowItem.visible = this._app.can_open_new_window();
        this.show();
    }

    destroy() {
        this._tracker.disconnectObject(this);
        Main.overview.disconnectObject(this);
        super.destroy();
    }
});

export default class OhMyMacExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._settings.connectObject('changed', () => this._reapply(), this);
        this._apply();
    }

    disable() {
        this._settings?.disconnectObject(this);
        this._settings = null;
        this._revert();
    }

    _reapply() {
        this._revert();
        this._apply();
    }

    _apply() {
        // Dark menu bar text on light wallpapers, like macOS in light mode.
        this._interface = new Gio.Settings({schema_id: 'org.gnome.desktop.interface'});
        this._interface.connectObject('changed::color-scheme', () => this._syncPanelScheme(), this);
        this._syncPanelScheme();

        if (this._settings.get_boolean('app-menu')) {
            this._appMenu = new AppMenuButton();
            Main.panel.addToStatusArea('ohmymac-app-menu', this._appMenu,
                Main.panel._leftBox.get_n_children(), 'left');
        }

        if (this._settings.get_boolean('clock-right'))
            this._moveClock(Main.panel._rightBox, -1);

        if (this._settings.get_boolean('notifications-right')) {
            this._bannerAlignment = Main.messageTray.bannerAlignment;
            Main.messageTray.bannerAlignment = Clutter.ActorAlign.END;
        }

        const activities = Main.panel.statusArea.activities;
        if (this._settings.get_boolean('hide-activities') && activities) {
            // Other extensions and session-mode changes show it again;
            // keep it hidden for as long as we are enabled.
            activities.container.hide();
            activities.container.connectObject('show', c => c.hide(), this);
            this._activitiesHidden = true;
        }
    }

    // The class goes on the panel's boxes: other extensions reset the
    // style classes of #panel itself.
    _panelBoxes() {
        return [Main.panel._leftBox, Main.panel._centerBox, Main.panel._rightBox];
    }

    _syncPanelScheme() {
        const light = this._interface.get_string('color-scheme') !== 'prefer-dark';
        for (const box of this._panelBoxes()) {
            if (light)
                box.add_style_class_name('ohmymac-light');
            else
                box.remove_style_class_name('ohmymac-light');
        }
    }

    _revert() {
        this._interface?.disconnectObject(this);
        this._interface = null;
        for (const box of this._panelBoxes())
            box.remove_style_class_name('ohmymac-light');
        this._appMenu?.destroy();
        this._appMenu = null;

        if (this._clockMoved) {
            this._moveClock(Main.panel._centerBox, 0);
            this._clockMoved = false;
        }

        if (this._bannerAlignment !== undefined) {
            Main.messageTray.bannerAlignment = this._bannerAlignment;
            this._bannerAlignment = undefined;
        }

        if (this._activitiesHidden) {
            Main.panel.statusArea.activities?.container.disconnectObject(this);
            Main.panel.statusArea.activities?.container.show();
            this._activitiesHidden = false;
        }
    }

    _moveClock(box, index) {
        const container = Main.panel.statusArea.dateMenu?.container;
        if (!container)
            return;
        container.get_parent()?.remove_child(container);
        if (index < 0)
            box.add_child(container);
        else
            box.insert_child_at_index(container, index);
        this._clockMoved = box === Main.panel._rightBox;
    }
}
