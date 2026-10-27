// SPDX-License-Identifier: GPL-3.0-or-later
//
// OhMyMac Lock Screen — the macOS lock and login screens on GNOME Shell 47–51.
//
//                     Tuesday 27 October
//                           9:41
//
//
//                          (avatar)
//                            Name
//                     [ Enter Password ]
//
// The Shell keeps its own dialogs and authentication; this only rearranges
// them. A large clock (date above the time) stays at the top, the user and the
// password field sit in the lower third, and the wallpaper stays sharp. It
// runs in the user session (lock screen) and, installed system-wide, in GDM
// (login screen). Every change is reverted in disable().

import Clutter from 'gi://Clutter';
import GnomeDesktop from 'gi://GnomeDesktop';
import GObject from 'gi://GObject';
import Shell from 'gi://Shell';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as Layout from 'resource:///org/gnome/shell/ui/layout.js';
import * as ScreenShield from 'resource:///org/gnome/shell/ui/screenShield.js';
import * as UserWidget from 'resource:///org/gnome/shell/ui/userWidget.js';
import {LoginDialog} from 'resource:///org/gnome/shell/gdm/loginDialog.js';
import {UnlockDialog} from 'resource:///org/gnome/shell/ui/unlockDialog.js';
import {formatDateWithCFormatString} from 'resource:///org/gnome/shell/misc/dateUtils.js';
import {Extension, InjectionManager, gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

// Top of the user block, as a fraction of the monitor height.
const PROMPT_TOP = 0.66;
// Space left under the user list on the login screen, same unit.
const LIST_BOTTOM = 0.12;
// The lock screen wallpaper: sharp, only slightly dimmed.
const BACKGROUND_BRIGHTNESS = 0.85;
// Gap between the clock and lock screen notifications, in pixels.
const NOTIFICATIONS_GAP = 24;

// St.BoxLayout gained "orientation" in GNOME 48; 47 only has "vertical".
function setVertical(box, vertical) {
    if ('orientation' in box)
        box.orientation = vertical ? Clutter.Orientation.VERTICAL : Clutter.Orientation.HORIZONTAL;
    else
        box.vertical = vertical;
}

const MacClock = GObject.registerClass(
class OhMyMacLockClock extends St.BoxLayout {
    _init() {
        super._init({
            style_class: 'ohmymac-lock-clock',
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.START,
            // BinLayout only honours y_align for children that expand.
            y_expand: true,
        });
        setVertical(this, true);

        this._date = new St.Label({
            style_class: 'ohmymac-lock-date',
            x_align: Clutter.ActorAlign.CENTER,
        });
        this._time = new St.Label({
            style_class: 'ohmymac-lock-time',
            x_align: Clutter.ActorAlign.CENTER,
        });
        this.add_child(this._date);
        this.add_child(this._time);

        this._wallClock = new GnomeDesktop.WallClock({time_only: true});
        this._wallClock.connect('notify::clock', () => this._update());
        this.connect('destroy', () => this._wallClock.run_dispose());
        this._update();
    }

    _update() {
        // macOS shows no AM/PM under the big digits.
        this._time.text = this._wallClock.clock.replace(/\s*[AP]M$/i, '').trim();
        const format = Shell.util_translate_time_string('%A %B %-d');
        this._date.text = formatDateWithCFormatString(new Date(), format);
    }
});

export default class OhMyMacLockScreenExtension extends Extension {
    enable() {
        this._decorated = new Map();
        this._injections = new InjectionManager();
        const extension = this;

        // Dialogs the Shell creates from now on (every lock, and GDM).
        this._injections.overrideMethod(ScreenShield.ScreenShield.prototype, '_ensureUnlockDialog',
            original => function (...args) {
                const result = original.apply(this, args);
                if (this._dialog)
                    extension._decorate(this._dialog);
                return result;
            });

        this._injections.overrideMethod(UnlockDialog.prototype, '_updateBackgroundEffects',
            original => function () {
                original.call(this);
                for (const widget of this._backgroundGroup)
                    widget.get_effect('blur')?.set({brightness: BACKGROUND_BRIGHTNESS, radius: 0});
            });

        // Login screen: the prompt in the lower third, the user list at the
        // bottom (the Shell centres both).
        this._injections.overrideMethod(LoginDialog.prototype, '_getFixedTopActorAllocation',
            original => function (dialogBox, actor) {
                const box = original.call(this, dialogBox, actor);
                const height = box.get_height();
                box.y1 = Math.floor(dialogBox.y1 + dialogBox.get_height() * PROMPT_TOP);
                box.y2 = box.y1 + height;
                return box;
            });
        this._injections.overrideMethod(LoginDialog.prototype, '_getCenterActorAllocation',
            original => function (dialogBox, actor) {
                const box = original.call(this, dialogBox, actor);
                const shift = Math.floor(dialogBox.get_height() * LIST_BOTTOM);
                box.y1 -= shift;
                box.y2 -= shift;
                return box;
            });

        // A dialog that is already up (GDM may show it before extensions load).
        const dialog = Main.screenShield?._dialog;
        if (dialog)
            this._decorate(dialog);

        // The big clock replaces the menu bar clock on the login screen.
        const dateMenu = Main.panel.statusArea.dateMenu?.container;
        if (Main.sessionMode.isGreeter && dateMenu) {
            dateMenu.hide();
            dateMenu.connectObject('show', c => c.hide(), this);
            this._hiddenDateMenu = dateMenu;
        }
    }

    disable() {
        // Injections first, so the undo steps below restore stock behaviour.
        this._injections.clear();
        this._injections = null;

        for (const [dialog, undo] of this._decorated) {
            dialog.disconnectObject(this);
            for (const step of undo.reverse())
                step();
            dialog.queue_relayout();
        }
        this._decorated = null;

        this._hiddenDateMenu?.disconnectObject(this);
        this._hiddenDateMenu?.show();
        this._hiddenDateMenu = null;
    }

    _decorate(dialog) {
        if (this._decorated.has(dialog))
            return;

        const undo = [];
        if (dialog instanceof UnlockDialog)
            this._decorateUnlock(dialog, undo);
        else if (dialog instanceof LoginDialog)
            this._decorateLogin(dialog, undo);
        else
            return;

        this._decorated.set(dialog, undo);
        dialog.connectObject('destroy', () => this._decorated.delete(dialog), this);
        dialog.queue_relayout();
    }

    // A full-monitor layer holding the clock, under the dialog's own content.
    _addClock(parent, sibling) {
        const layer = new St.Widget({
            layout_manager: new Clutter.BinLayout(),
            constraints: new Layout.MonitorConstraint({primary: true}),
        });
        layer.add_child(new MacClock());
        parent.insert_child_below(layer, sibling);
        return layer;
    }

    _decorateUnlock(dialog, undo) {
        const mainBox = dialog._stack.get_parent();
        const layer = this._addClock(dialog, mainBox);
        undo.push(() => layer.destroy());

        // The Shell's clock page becomes the idle user block: avatar, name
        // and a password pill, laid out like the prompt that replaces it.
        const page = dialog._clock;
        const stock = [page._time, page._date, page._hint];
        stock.forEach(label => label.hide());
        page.add_style_class_name('ohmymac-lock-idle');
        const user = new UserWidget.UserWidget(dialog._user, Clutter.Orientation.VERTICAL);
        const pill = new St.Label({
            style_class: 'ohmymac-lock-pill',
            text: _('Enter Password'),
            x_align: Clutter.ActorAlign.CENTER,
        });
        page.add_child(user);
        page.add_child(pill);
        undo.push(() => {
            user.destroy();
            pill.destroy();
            stock.forEach(label => label.show());
            page.remove_style_class_name('ohmymac-lock-idle');
        });

        // The Shell centres the user block and puts notifications at the
        // bottom; move them to the lower third and under the clock.
        const clock = layer.get_first_child();
        const place = () => this._placeUnlock(dialog, mainBox, clock);
        for (const actor of [dialog._stack, dialog._notificationsBox, clock])
            actor.connectObject('notify::allocation', place, this);
        undo.push(() => {
            for (const actor of [dialog._stack, dialog._notificationsBox])
                actor.disconnectObject(this);
            dialog._stack.translation_y = 0;
            dialog._notificationsBox.translation_y = 0;
        });

        dialog._updateBackgroundEffects();
        undo.push(() => dialog._updateBackgroundEffects());
    }

    _placeUnlock(dialog, mainBox, clock) {
        const stack = dialog._stack;
        const notifications = dialog._notificationsBox;
        // Unallocated actors report infinite boxes; wait for the real ones.
        if (![mainBox, stack, notifications, clock].every(a => a.has_allocation()))
            return;
        stack.translation_y = Math.floor(mainBox.height * PROMPT_TOP) - stack.allocation.y1;
        notifications.translation_y =
            clock.allocation.y2 + NOTIFICATIONS_GAP - notifications.allocation.y1;
    }

    _decorateLogin(dialog, undo) {
        // The clock lives next to the dialog, so it may outlive it or go first.
        let layer = this._addClock(dialog.get_parent(), dialog);
        layer.connect('destroy', () => (layer = null));
        dialog.connectObject('destroy', () => layer?.destroy(), this);
        undo.push(() => layer?.destroy());

        // No distribution logo on a Mac login window.
        dialog._logoBin.hide();
        undo.push(() => dialog._logoBin.show());

        // Users side by side at the bottom, each avatar above its name.
        const selection = dialog._userSelectionBox;
        const align = selection.y_align;
        selection.y_align = Clutter.ActorAlign.END;
        const list = dialog._userList._box;
        setVertical(list, false);
        list.x_align = Clutter.ActorAlign.CENTER;
        list.get_children().forEach(item => this._stackItem(item, undo));
        list.connectObject('child-added', (_box, item) => this._stackItem(item, undo), this);
        undo.push(() => {
            list.disconnectObject(this);
            setVertical(list, true);
            list.x_align = Clutter.ActorAlign.FILL;
            selection.y_align = align;
        });
    }

    _stackItem(item, undo) {
        const old = item._userWidget;
        if (!old?.get_parent())
            return;
        const widget = new UserWidget.UserWidget(item.user, Clutter.Orientation.VERTICAL);
        old.get_parent().insert_child_below(widget, old);
        old.hide();
        item.label_actor = widget.label_actor;
        undo.push(() => {
            widget.destroy();
            old.show();
            item.label_actor = old.label_actor;
        });
    }
}
