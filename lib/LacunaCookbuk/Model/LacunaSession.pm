use v6;

use LacunaCookbuk::Config;
use JSON::RPC::Client;

#! Every object that requires session id should inherrit from LacunaSession
class LacunaSession;

constant $EMPIRE = '/empire';
my %.status;
my $.session_id;

method lacuna_url(Str $url){
    'http://us1.lacunaexpanse.com'~ $url
}

method rpc(Str $name --> JSON::RPC::Client) is cached {
    JSON::RPC::Client.new( url => self.lacuna_url($name))
}

method create_session {
  my %logged = self.rpc($EMPIRE).login(|%login);
  %.status = %logged<status>;
  $.session_id = %logged<session_id>
}

method close_session {
    self.rpc($EMPIRE).logout($.session_id);
}

method planet_name($planet_id --> Str){
    self.status<empire><planets>{$planet_id};
}

method home_planet_id{
    self.status<empire><home_planet_id>;
}

method planets_hash {
    self.status<empire><planets>;
}
