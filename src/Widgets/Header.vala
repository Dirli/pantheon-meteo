/*
* Copyright (c) 2018-2020 Dirli <litandrej85@gmail.com>
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

namespace Meteo {
    public class Widgets.Header : Gtk.HeaderBar {
        public signal void show_preferences ();
        public signal void change_location ();
        public signal void update_data ();

        private Gtk.Button loc_button;
        private Gtk.Button upd_button;

        public bool auto_location {
            get; set;
        }

        public string idplace {
            set {
                if (value != "" || value != "0") {
                    upd_button.sensitive = true;
                    loc_button.sensitive = !auto_location;
                } else {
                    upd_button.sensitive = false;
                    loc_button.sensitive = false;
                }
            }
        }

        public Header () {
            get_style_context ().add_class ("compact");
            show_close_button = true;

            //Create menu
            var about_button = new Gtk.ModelButton ();
            about_button.text = _("About");
            about_button.clicked.connect (() => {
                var about = new Dialogs.About ();
                about.show ();
            });

            var pref_button = new Gtk.ModelButton ();
            pref_button.text = _("Preferences");
            pref_button.clicked.connect (() => {
                show_preferences ();
            });

            var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            menu_box.add (pref_button);
            menu_box.add (about_button);
            menu_box.show_all ();

            var popover_menu = new Gtk.Popover (null);
            popover_menu.add (menu_box);

            var app_button = new Gtk.MenuButton ();
            app_button.popover = popover_menu;
            app_button.tooltip_text = _("Options");
            app_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON);

            //Right buttons
            upd_button = new Gtk.Button.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.BUTTON);
            upd_button.sensitive = false;
            upd_button.tooltip_text = _("Update");
            upd_button.clicked.connect (() => {
                update_data ();
            });

            loc_button = new Gtk.Button.from_icon_name ("mark-location-symbolic", Gtk.IconSize.BUTTON);
            loc_button.tooltip_text = _("Change location");
            loc_button.clicked.connect (() => {
                change_location ();
            });

            pack_start (loc_button);
            pack_end (app_button);
            pack_end (upd_button);
        }
    }
}
