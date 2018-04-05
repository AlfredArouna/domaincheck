#!/usr/bin/perl
use Net::IDN::Encode ':all';
use Net::LibIDN ':all';
$input = <STDIN>;
$name = idn_to_ascii("$input",'utf-8');
print $name;
