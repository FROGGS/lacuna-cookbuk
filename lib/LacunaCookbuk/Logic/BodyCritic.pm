use v6;

use LacunaCookbuk::Logic;
use Form;
use Term::ANSIColor;

#| TODO split
class BodyCritic is Logic;

constant $limited_format= '{<<<<<<<<<<<<<<<<<<<<<<<<<<<} {>>>>}/{<<<<} {>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>}';
constant $ore_format_str = '{<<<<<<<<<<<<<<<<<<<}  ' ~ '{||||} ' x 20;
constant $ruler = '-' x 160;
constant $ship_templ = '{<<<<<<<<<<<<<<<<<<<<<<<<<} ' ~ ' {>>>>>>>} ' x 6;

submethod elaborate_spaceport(Planet $planet --> SpacePort) {
    
    my SpacePort $spaceport = $planet.find_space_port;

#bug?
    my Int $free = $spaceport.docks_available;    
    my Str $docks = $free == 0 ?? "FULL" !! ~$free;
    my Str $max = ~$spaceport.max_ships;
    my %shipz = $spaceport.docked_ships;
    my Str $ships = self.format_ships(%shipz);
    
    
    print form( 
	$limited_format,
	$planet.name, $docks, $max, $ships);

    return $spaceport;
}

submethod elaborate_intelligence(Planet $planet) {
    my Intelligence $imini = $planet.find_intelligence_ministry;
    my Str $numspies = ~$imini.current;
    my Str $max = ~$imini.maximum;   
    my Str $spies = $numspies == 0 ?? "NONE!!!" !! ~$numspies;
    
    my Str $spiesl = self.format_spies($imini.get_view_spies);
    
    print form( 
	$limited_format,
	$planet.name, $spies, $max, $spiesl);

}

submethod elaborate_ores(Planet $planet, Str @header) {
#keys and values in hash 
    my Str @header_copy = @header.clone;
    @header_copy.shift;

    my Str @values = gather for @header_copy -> $head {
	take ~$planet.ore{$head};
    }
    @values.unshift($planet.name);
    print form($ore_format_str, @values);
}

submethod elaborate_ore {

    say "Planets -- Potential ores";
    my Str @header = self.bodybuilder.home_planet.ore.keys;
    @header.unshift('Planet name');
    print BOLD, form($ore_format_str, @header), RESET;
    
    for self.bodybuilder.planets -> Planet $planet {
	self.elaborate_ores($planet, @header);
    }    
}


submethod elaborate_ships {   
    my %ports; 
    {
	say BOLD,"\n\nSpaceport -- Docks";
	my @header = <planet free all details>;
	print  form ($limited_format, @header);
	say $ruler, RESET;
	for self.bodybuilder.planets -> Planet $planet {
	    %ports{$planet.name} = self.elaborate_spaceport($planet);
	}

    }
    {
	my %available = self.bodybuilder.home_planet.find_shipyard.get_buildable;
	for %ports.pairs -> $pair {
	    
	    my @shipz = $pair.value.view_all_ships;
	    say;
	    say BOLD, $pair.key;
	    say $ruler,;
	    print form($ship_templ, 'Name', 'ID', 'Speed','Stealth', 'Hold size', 'Combat', 'Task'), RESET;
	    for @shipz -> @ship_h{

		for @ship_h -> %ship {
		    
		    my %compared = self.compare_ships(%ship, %available{%ship<type>}<attributes>);
		    my Str $color = 'reset';
		    $color = 'cyan' if any(%compared.values) > 100;
		    $color = 'yellow' if any(%compared.values) < 65;
		    $color = 'red' if any(%compared.values) < 45;
		    my Str $line = form($ship_templ,
					%ship<name>, ~%ship<id>,
					~(%compared<speed>),
					~(%compared<stealth>),
					~(%compared<hold_size>),
					~(%compared<combat>),
					~(%ship<task>)
			);
		    print colored($line, $color);
		}

	    }
	}
    }
}

method compare_ships(%existing, %reference --> Hash){
    my %ret;
    
    %ret<speed> = safe_divide(%existing<speed>,%reference<speed>);
    %ret<stealth> = safe_divide(%existing<stealth>,%reference<stealth>);
    %ret<hold_size> = safe_divide(%existing<hold_size>,%reference<hold_size>);    
    %ret<combat> = safe_divide(%existing<combat> , %reference<combat>);

    %ret;

}

sub safe_divide($a, $b --> Int) {
    return 100 if $a*$b == 0;
    return Int($a*100/$b);
    
}

submethod elaborate_spies{
    say "\nIntellignece -- Spies";
    my @header = <planet num limit details>;
    print form ($limited_format, @header);
    say $ruler;
    for self.bodybuilder.planets -> Planet $planet {
	self.elaborate_intelligence($planet);
    }
}




method format_ships(%ships --> Str) {
    my Str $ret;
    for %ships.keys -> Str $key {
	$ret ~=	 $key ~ ":" ~ %ships{$key} ~ ' ';
    }
    $ret;
}

method format_spies(Spy @spies --> Str) {
    my %assignments;
    for @spies -> Spy $spy {
	%assignments{$spy.assignment}++;
    }

    my Str $ret;
    for %assignments.keys -> Str $key {
	$ret ~=	$key ~ ':' ~%assignments{$key} ~ '   ';
    }
    $ret;
}
