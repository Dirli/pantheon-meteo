/*
 * Copyright (c) 2018-2020 Dirli <litandrej85@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace Meteo {
    public class Widgets.Header : Gtk.HeaderBar {
        public signal void show_preferences ();
        public signal void change_location ();
        public signal void changed_location (Structs.LocationStruct new_location);
        public signal void update_data ();

        private Gtk.Button loc_button;
        private Gtk.Button upd_button;

        public bool auto_location { get; set; }

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

        public void manual_detect () {
            var location_entry = new GWeather.LocationEntry (GWeather.Location.get_world ());
            location_entry.placeholder_text = _("Search for new location:");
            location_entry.width_chars = 30;

            location_entry.activate.connect (() => {
                GWeather.Location? location = location_entry.get_location ();

                if (location != null) {
                    double lon;
                    double lat;
                    location.get_coords (out lat, out lon);

                    Structs.LocationStruct new_loc = {};
                    new_loc.country = location.get_country_name ();
                    new_loc.city = location.get_city_name ();
                    new_loc.latitude = lat;
                    new_loc.longitude = lon;

                    changed_location (new_loc);
                } else {
                    // show_message ("location could not be determined");
                }

                location_entry = null;
            });

            set_custom_title (location_entry);
            show_all ();
        }

        public void remove_custome_title () {
            if (get_custom_title () != null) {
                custom_title = null;
            }
        }
    }
}
