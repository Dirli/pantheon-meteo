namespace Meteo {
    public class Services.SettingsWrapper : GLib.Settings {

        public SettingsWrapper () {
            Object (schema_id: Constants.APP_NAME);
        }

        public Structs.LocationStruct get_location () {
            Structs.LocationStruct location = {};

            location.city = get_string ("city");
            location.country = get_string ("country");
            location.latitude = get_double ("latitude");
            location.longitude = get_double ("longitude");
            location.idplace = get_string ("idplace");

            return location;
        }

        public void set_location (Structs.LocationStruct? loc) {
            if (loc != null) {
                set_string ("city", loc.city);
                set_string ("country", loc.country);
                set_double ("latitude", loc.latitude);
                set_double ("longitude", loc.longitude);
            } else {
                reset ("longitude");
                reset ("latitude");
                reset ("city");
                reset ("country");
                reset ("idplace");
            }
        }
    }
}
