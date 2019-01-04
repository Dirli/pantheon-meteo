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

    public class Statusbar : Gtk.ActionBar {
        private Gtk.Label new_msg;

        public Statusbar () {
            Gtk.Label owm_label = new Gtk.Label ("https://openweathermap.org/");
            owm_label.margin = 10;
            pack_end (owm_label);
            new_msg = new Gtk.Label ("");
            new_msg.margin = 10;
            pack_start (new_msg);
        }

        public void add_msg (string msg) {
            new_msg.set_text (msg);
        }
    }
}
