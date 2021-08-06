protected string city_name;
protected float lat;
protected float lon;


namespace Meteo {
    public class Providers.OWMProvider : Providers.AbstractProvider {
        public string id_place {get; construct set;}
        public string api_key {get; construct set;}

        public OWMProvider (string api, string id) {
            Object (api_key:api,
                    id_place: id);
        }

        public override void get_today_forecast () {
            
        }


    }
}
