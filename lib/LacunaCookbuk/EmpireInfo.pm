use v6;

use LacunaCookbuk::LacunaSession;
use LacunaCookbuk::RPCMaker;

use LacunaBuilding::Archaeology;
use LacunaBuilding::Trade;

class EmpireInfo is LacunaSession;

has $!body = RPCMaker.aq_client_for('/body');
has $!empire = RPCMaker.aq_client_for('/empire');

submethod getPlanetName($planet_id --> Str){
    self.status<empire><planets>{$planet_id};
}

submethod find_home_planet_id{
    self.status<empire><home_planet_id>;
}

submethod find_planets{
    self.status<empire><planets>;
}

submethod find_archeology_ministry($planet_id){
  
    for self.get_buildings($planet_id) -> %building {
	return Archaeology.new(id => %building<id>) if %building<url> ~~ '/archaeology';
    }
    warn "No archaeology ministry on $planet_id";
}   

#TODO move to planet related!!!!!!!
submethod find_trade_ministry($planet_id){
    
    for self.get_buildings($planet_id) -> %building {
	return Trade.new(id => %building<id>) if %building<url> ~~ '/trade';
    }
    warn "No trade ministry on $planet_id";
}   

submethod get_buildings($planet_id --> List){
    my %buildings = $!body.get_buildings(self.session_id, $planet_id);
    self.status = %buildings<status>;
    
    gather for keys %buildings<buildings> -> $building_id {
	my $url = %buildings<buildings>{$building_id}<url>;
	my $rpc = RPCMaker.aq_client_for($url);
	my %building =  $rpc.view(self.session_id, $building_id);
	self.status = %building<status>;
	%building<building><id> = $building_id;	 
	%building<building><url> = $url;
	take %building<building>;
    }     
}

submethod calculateSustainablity($planet_id){
    my %balance;

    for self.get_buildings($planet_id) -> %building {
	for (keys %building).grep(/_hour/) -> $key {
	    %balance{$key} += %building{$key};
	}
    }
    %balance;
}  
