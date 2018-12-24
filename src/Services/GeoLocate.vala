namespace Meteo.Services {
    struct Coord {
        double lat;
        double lon;
    }
    public void geolocate () {
        GLib.Settings settings = Meteo.Services.Settings.get_default ();
        Coord mycoords = get_location ();
        string uri = Constants.OWM_API_ADDR + "weather";
        string uri_query = "?lat=" + mycoords.lat.to_string () + "&lon=" + mycoords.lon.to_string () + "&APPID=" + Constants.API_KEY;
        var location = new Geocode.Location (mycoords.lat, mycoords.lon);
        var reverse = new Geocode.Reverse.for_location (location);
        try {
            Geocode.Place mycity = reverse.resolve ();
            if (mycity != null && settings.get_string ("location") != mycity.town) {
                uri += uri_query;
                settings.set_string ("idplace", update_id (uri).to_string());
                settings.set_string ("location", mycity.town);
                settings.set_string ("state", mycity.state);
                settings.set_string ("country", mycity.country_code);

                Meteo.Utils.clear_cache ();
            }
        } catch (Error e) {
            warning (e.message);
        }
    }

    private static Coord get_location () {
        var coord = Coord ();
        string uri = "https://location.services.mozilla.com/v1/geolocate?key=test";
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", uri);
        session.send_message (message);
        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) message.response_body.flatten ().data, -1);
            var root = parser.get_root ().get_object ();
            foreach (string name in root.get_members ()) {
                if (name == "location") {
                    var mycoords = root.get_object_member ("location");
                    coord.lat = mycoords.get_double_member ("lat");
                    coord.lon = mycoords.get_double_member ("lng");
                    break;
                }
            }
        } catch (Error e) {
            warning (e.message);
        }
        return coord;
    }
    private static int64 update_id (string uri) {
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", uri);
        session.send_message (message);
        int64 id = 0;
        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) message.response_body.flatten ().data, -1);
            var root = parser.get_root ().get_object ();
            id = root.get_int_member ("id");
        } catch (Error e) {
            warning (e.message);
        }

        return id;
    }
}
