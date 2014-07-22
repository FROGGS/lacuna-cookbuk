use v6;

use LacunaCookbuk::Model::Body;
use LacunaCookbuk::Logic::BodyBuilder;
use LacunaCookbuk::Logic::Chairman::Building;
use LacunaCookbuk::Logic::Chairman::Resource;
use LacunaCookbuk::Logic::Chairman::BuildGoal;

use Term::ANSIColor;

class Chairman;

has BuildGoal @.build_goals;

constant $UNSUSTAINABLE = 1012;
constant $NO_ROOM_IN_QUEUE = 1009;
constant $INCOMPLETE_PENDING_BUILD = 1010;
constant $NOT_ENOUGH_STORAGE = 1011;



method build(Body $body) {
    for self.build_goals -> BuildGoal $goal {
	#| to avoid infinite recurence
	#| may be not needed TODO: check
      constant TRIAL_LIMIT = 5;
      my $alt_goal = $goal;
      my $trial = 0;
	repeat {
	    return if $alt_goal.level < 1;
	    last if ++$trial == TRIAL_LIMIT;	    
	    $alt_goal = self.upgrade($body, $alt_goal);
	} while $alt_goal

   }
}

method upgrade(Body $body, BuildGoal $goal --> BuildGoal){
    my LacunaBuilding @buildings = $body.find_buildings('/' ~ $goal.building);
   
    
    for @buildings -> LacunaBuilding $building {
	warn $building.perl;
	my $view = $building.view;
	next unless $goal.level > $view.level;#goal reached

	
	if $view.upgrade<can> {
	    $building.upgrade;
	    note colored("Upgrade started " ~ $goal.building, 'green');
	} else {
	    given $view.upgrade<reason>[0] {
		when $UNSUSTAINABLE {
		    unless $view.upgrade<reason>[2] {
			note colored($view.upgrade<reason>[1] ~ "do it yourself", 'red');
			next
		    }

		    my Resource $resource = value_of($view.upgrade<reason>[2]);
		    note 'Need to produce more ' ~ $resource  ~ ' for ' ~ $goal.building;
		    my $new_goal =  BuildGoal.new(building => self.production($resource), level => 15);
		    if $new_goal.building != $goal.building {
			note "Too low $resource for upgrading {$new_goal.building}";
			return $new_goal;
			} else {
			note "Cannot upgrade itself";
			next
		    }
		}
		when $NOT_ENOUGH_STORAGE {
		    my Resource $resource = value_of($view.upgrade<reason>[2]);
		    my $quantity = $view.upgrade<cost>{$resource};
		    my $status = $body.get_status<body>;
		    my $capacity = $status{$resource ~ '_capacity'};
		    note "Need to have $quantity of $resource for {$goal.building}";
		    
		    if  $quantity > $capacity {
			note "To small stores will try to upgrade";
			my $new_goal = BuildGoal.new(building=> self.storage($resource), level => 15);
			return $new_goal unless $new_goal.building == $goal.building;
			} else {
			note "Capacity of $capacity is sufficent, stores will be left as is";
		    }
		}
		when $NO_ROOM_IN_QUEUE {
		    note 'Queue full';
		    # Unclean
		    return BuildGoal.new(level => -1); 
			#last;
		}
		when $INCOMPLETE_PENDING_BUILD {next}
		default {die $view.upgrade}
	    }		
	}
    }    
    BuildGoal;
}

method storage(Resource $resource --> Building::Building) {
    
    given $resource {
	when food {return Building::Building::foodreserve}
	when ore {return Building::Building::orestorage}
	when water {return Building::Building::waterstorage}
	when waste {return Building::Building::wastesequestration}
	when energy {return Building::Building::energyreserve}
	default{die $resource}
    }
}

method production(Resource $resource --> Building::Building) {
    
    given $resource {
	when food {
	    my @array of Building::Building = (Building::Building::dairy, 
				     Building::Building::lapis,
				     Building::Building::apple,
				     Building::Building::beeldeban,
				     Building::Building::algae,
				     Building::Building::malcud
		);
	    return @array.pick }#FIXME
	when ore {
	    my @array of Building::Building = (Building::Building::mine, Building::Building::orerefinery);
	    return  @array.pick
	}
	when water {return Building::Building::atmosphericevaporator}
#	when waste {return Building::wastesequestration}
	when energy {return Building::Building::singularity}
	default{die $resource}
    }
}


method all {
    for (planets) -> Body $planet {
	next if $planet.is_home;
	note BOLD, "Upgrading " ~ $planet.name, RESET;
	self.build($planet)
    }
}

sub value_of(Str $str --> Resource){
    given $str {
	when 'food' {return food;}
	when 'ore' {return ore;}
	when 'water' {return water;}
	when 'energy' {return energy;}
	when 'waste' {return waste;}
	when 'happiness' {return happiness;}
	default{die $str}

    }
}
