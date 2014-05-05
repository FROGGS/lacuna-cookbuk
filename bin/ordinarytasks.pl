use v6;



use LacunaCookbuk::Config;
use JSON::RPC::Client;

class Trade {
    has $!traderpc = JSON::RPC::Client.new( url => 'http://us1.lacunaexpanse.com/trade');
    has $.id;
    has $.session_id;


    method getGlyphs {
	$!traderpc.get_glyph_summary($.session_id, $.id)<glyphs>;
    } 

    method getResources {
	$!traderpc.get_stored_resources($.session_id, $.id)<resources>;
    }

    
    method getPlans {
	$!traderpc.get_plan_summary($.session_id, $.id)<plans>;
    } 

    method getPushShips ($targetId) {
	$!traderpc.get_trade_ships($.session_id, $.id, $targetId)<ships>;

    }


    #metohd push ($destination, $what){!!!}


}

class EmpireInfo {

    has %!session;
    has $!body = JSON::RPC::Client.new( url => 'http://us1.lacunaexpanse.com/body');
    has $!empire = JSON::RPC::Client.new( url => 'http://us1.lacunaexpanse.com/empire');

    method find_home_planet_id{
	%!session<status><empire><home_planet_id>;
    }

    method find_planets{
	%!session<status><empire><planets>;
    }

    method find_trade_ministry($planet_id){
	my %buildings = $!body.get_buildings(self!session_id, $planet_id)<buildings>;
	for keys %buildings -> $building_id {
	    return Trade.new(id => $building_id, session_id => self!session_id) if %buildings{$building_id}<url> ~~ '/trade';
	}
	#die("No trade ministry on $planet_id");
    }

    submethod !session_id{
	%!session<session_id>;
    }


    submethod create_session{
	%!session = $!empire.login(|%login);
    }

    submethod close_session(){
	$!empire.logout(self!session_id);
    }
}


my $f = EmpireInfo.new;
$f.create_session;

my $home_planet_id = $f.find_home_planet_id;
my @planets = keys $f.find_planets;

for @planets -> $planet_id {
    next if $planet_id == $home_planet_id;
    my $trade = $f.find_trade_ministry($planet_id);
    if $trade
    {
	say $trade.getPushShips($planet_id);
#	say $trade.getPlans;
#	say $trade.getGlyphs;
    }
}

$f.close_session;




