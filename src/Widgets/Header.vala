/*
* Copyright (c) 2018 Dirli <litandrej85@gmail.com>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*/

namespace Meteo.Widgets {
    public class Header : Gtk.HeaderBar {
        public signal void show_preferences ();

        private Gtk.Button loc_button;
        public Gtk.Button upd_button;
        private GLib.Settings settings;

        public Header (Meteo.MainWindow window) {
            settings = Meteo.Services.SettingsManager.get_default ();

            show_close_button = true;

            //Create menu
            Gtk.Menu menu = new Gtk.Menu ();
            var pref_item = new Gtk.MenuItem.with_label (_("Preferences"));
            var about_item = new Gtk.MenuItem.with_label (_("About"));
            menu.add (pref_item);
            menu.add (about_item);
            pref_item.activate.connect (() => {
                show_preferences ();
            });
            about_item.activate.connect (() => {
                var about = new Meteo.Dialogs.About ();
                about.show ();
            });

            var app_button = new Gtk.MenuButton ();
            app_button.popup = menu;
            app_button.tooltip_text = _("Options");
            app_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON);
            menu.show_all ();

            //Right buttons
            upd_button = new Gtk.Button.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.BUTTON);
            upd_button.sensitive = false;
            upd_button.tooltip_text = _("Update");

            pack_end (app_button);
            pack_end (upd_button);

            loc_button = new Gtk.Button.from_icon_name ("mark-location-symbolic", Gtk.IconSize.BUTTON);
            loc_button.tooltip_text = _("Change location");
            loc_button.clicked.connect (() => {
                Meteo.Utils.clear_cache ();
                settings.reset ("idplace");
            });

            pack_end (loc_button);
            refresh_btns ();
        }

        public void refresh_btns () {
            string idp = settings.get_string ("idplace");
            if (idp != "" || idp != "0") {
                upd_button.sensitive = true;
                if (settings.get_boolean ("auto")) {
                    loc_button.sensitive = false;
                } else {
                    loc_button.sensitive = true;
                }
            } else {
                upd_button.sensitive = false;
                loc_button.sensitive = false;
            }
        }
    }
}
