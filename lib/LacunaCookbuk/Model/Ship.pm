use v6;

use LacunaCookbuk::Model::LacunaSession;

class Ship is LacunaSession;
has %.attr;

multi method gist {
    if %.attr<task> eq "Travelling"
    {
    return join "\n\t", 
	 %.attr<from><name> ~ " -> " ~ %.attr<to><name>,
	 %.attr<type_human> ~ ": " ~ "ETA " ~ %.attr<date_arrives>,
	 "[" ~ %.attr<payload> ~ "]"; 
    } else {
	return "";
	warn "Could not format %.attr";
    }

}

