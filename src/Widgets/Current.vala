namespace Meteo.Widgets {
    public class Current : Gtk.Box {
        public Current (Meteo.MainWindow window) {
            GLib.Settings settings = Meteo.Services.Settings.get_default ();
            orientation = Gtk.Orientation.HORIZONTAL;

            string idplace = settings.get_string ("idplace");
            string lang = Gtk.get_default_language ().to_string ().substring (0, 2);
            string units = settings.get_string ("units");
            string uri_query = "?id=" + idplace + "&APPID=" + Constants.API_KEY + "&units=" + units + "&lang=" + lang;

            string uri = Constants.OWM_API_ADDR + "weather" + uri_query;
            Json.Object? today_obj = Meteo.Services.Connector.get_owh_data (uri, "current");
            Gtk.Grid today = new Meteo.Widgets.Today (today_obj);

            uri = Constants.OWM_API_ADDR + "forecast" + uri_query;
            Json.Object? forecast_obj = Meteo.Services.Connector.get_owh_data (uri, "forecast");
            Gtk.Grid forecast = new Meteo.Widgets.Forecast (forecast_obj);

            Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);

            pack_start (today, true, true, 0);
            pack_start (separator, false, true, 0);
            pack_start (forecast, true, true, 0);
        }
    }
}
