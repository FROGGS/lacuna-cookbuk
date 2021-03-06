use v6;


use LacunaCookbuk::Model::Body::SpaceStation;
use LacunaCookbuk::Model::Building::Parliament;
use LacunaCookbuk::Logic::BodyBuilder;

class Ambassador;


submethod vote_all(Bool $vote) {
    for (stations) -> SpaceStation $station {
	my Parliament $par = $station.find_parliament;
	next unless $par;
	my @prop = $par.view_propositions;
	for @prop -> @weirdo {
	    for @weirdo -> $to_vote {
		next unless $to_vote;
		
		my $number = $vote ?? "1" !! "0";		
		say $par.cast_vote($to_vote<id>, $number) unless $to_vote<my_vote>:exists;#FIXME
	    }
	}
    }
}

