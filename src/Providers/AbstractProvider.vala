namespace Meteo {
    public abstract class Providers.AbstractProvider : GLib.Object {
        public int64 sunrise { get; set; }
        public int64 sunset { get; set; }

        public abstract Gee.ArrayList<Structs.WeatherStruct?> get_long_forecast (string u);
        public abstract Structs.WeatherStruct? get_today_forecast (string u);
    }
}
