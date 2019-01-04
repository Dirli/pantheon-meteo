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

namespace Meteo {
    public class MeteoApp : Gtk.Application {
        public MainWindow window;

        public MeteoApp () {
            application_id = "io.elementary.meteo";
            flags |= GLib.ApplicationFlags.FLAGS_NONE;
        }

        public override void activate () {
            if (get_windows () == null) {
                window = new MainWindow (this);
                window.show_all ();
                window.start_follow ();
            } else {
                window.present ();
            }
        }

        public static void main (string [] args) {
            var app = new Meteo.MeteoApp ();
            app.run (args);
        }
    }
}
