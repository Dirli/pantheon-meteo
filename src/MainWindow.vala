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
            this.set_default_size (950, 560);
            this.set_size_request (950, 560);
            window_position = Gtk.WindowPosition.CENTER;
            header = new Meteo.Widgets.Header (this, false);

            Gtk.CssProvider provider = new Gtk.CssProvider();
            provider.load_from_resource ("/io/elementary/meteo/application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            settings = Meteo.Services.Settings.get_default ();

            header.upd_button.clicked.connect (() => {
                var current = new Meteo.Widgets.Current (this);
                change_view (current);
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
            var current = new Meteo.Widgets.Current (this);
            change_view (current);

            settings.changed.connect(on_settings_change);
        }

        public void change_view (Gtk.Box widget) {

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
                        var current = new Meteo.Widgets.Current (this);
                        change_view (current);
                    }
                break;
            }
        }
    }
}
