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
