/*
 * Copyright (c) 2018-2021 Dirli <litandrej85@gmail.com>
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
    public class Widgets.Panel : Gtk.Box {
        private Gtk.Label temp;
        private Gtk.Image weather_icon;

        public Panel () {
            Object (orientation: Gtk.Orientation.HORIZONTAL);
        }

        construct {
            weather_icon = new Gtk.Image ();
            temp = new Gtk.Label (null);
            pack_start (weather_icon, false, false, 0);
            pack_start (temp, false, false, 0);
        }

        public void update_state (string temp_str, string icon_name) {
            temp.label = temp_str;
            weather_icon.set_from_icon_name (icon_name, Gtk.IconSize.SMALL_TOOLBAR);
        }
    }
}
