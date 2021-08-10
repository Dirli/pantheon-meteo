namespace Meteo {
    public abstract class Providers.AbstractProvider : GLib.Object {
        public signal void show_message (string msg);
        public signal void updated_today (Structs.WeatherStruct w);
        public signal void updated_long (Gee.ArrayList<Structs.WeatherStruct?> f);

        public int64 sunrise { get; set; }
        public int64 sunset { get; set; }

        public abstract void update_forecast (bool advanced, string units);
    }
}
