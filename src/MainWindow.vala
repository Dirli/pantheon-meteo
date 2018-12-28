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
    public class MainWindow : Gtk.Window {
        public MeteoApp app;
        private Gtk.Grid view;
        private GLib.Settings settings;
        private Meteo.Widgets.Header header;
        public Meteo.Widgets.Ticket ticket;

        public MainWindow (MeteoApp app) {
            this.app = app;
            this.set_application (app);
            this.set_default_size (950, 450);
            this.set_size_request (950, 450);
            window_position = Gtk.WindowPosition.CENTER;
            header = new Meteo.Widgets.Header (this, false);

            Gtk.CssProvider provider = new Gtk.CssProvider();
            provider.load_from_resource ("/io/elementary/meteo/application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            settings = Meteo.Services.Settings.get_default ();

            header.upd_button.clicked.connect (() => {
                change_view ();
            });

            this.set_titlebar (header);

            var overlay = new Gtk.Overlay ();
            view = new Gtk.Grid ();
            view.expand = true;
            view.halign = Gtk.Align.FILL;
            view.valign = Gtk.Align.FILL;
            view.attach (new Gtk.Label("Loading ..."), 0, 0, 1, 1);
            overlay.add_overlay (view);

            ticket = new Meteo.Widgets.Ticket ("");
            overlay.add_overlay (ticket);

            add (overlay);
            this.show_all ();

            Meteo.Services.geolocate ();
            change_view ();

            settings.changed.connect(on_settings_change);
        }

        public void change_view () {
            var widget = new Meteo.Widgets.Current (this);

            header.custom_title = null;

            string location_title = settings.get_string ("location") + ", ";
            if (settings.get_string ("location") != settings.get_string ("state")) {
                location_title += settings.get_string ("state") + " ";
            }
            location_title += settings.get_string ("country");

            header.set_title (location_title);

            this.view.get_child_at (0,0).destroy ();
            widget.expand = true;
            this.view.attach (widget, 0, 0, 1, 1);
            widget.show_all ();
        }

        private void on_settings_change(string key) {
            switch (key) {
                case "refresh":
                    if (settings.get_boolean ("refresh")) {
                        change_view ();
                    }
                break;
            }
        }
    }
}
