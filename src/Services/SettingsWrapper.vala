namespace Meteo {
    public class Services.SettingsWrapper : GLib.Settings {

        public SettingsWrapper () {
            Object (schema_id: Constants.APP_NAME);
        }

        public Structs.LocationStruct get_location () {
            Structs.LocationStruct location = {};

            location.city = get_string ("city");
            location.country = get_string ("country");
            location.idplace = get_string ("idplace");

            double lat;
            double lon;

            @get ("coords", "(dd)", out lat, out lon);
            location.latitude = lat;
            location.longitude = lon;

            return location;
        }

        public void set_location (Structs.LocationStruct? loc) {
            if (loc != null) {
                set_string ("city", loc.city ?? "");
                set_string ("country", loc.country ?? "");
                @set ("coords", "(dd)", loc.latitude, loc.longitude);
            } else {
                reset ("coords");
                reset ("city");
                reset ("country");
                reset ("idplace");
            }
        }
    }
}
