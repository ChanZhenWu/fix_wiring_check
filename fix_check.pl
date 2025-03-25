#!/usr/bin/perl
print "\n*****************************************************************************\n";
print "  3070 wiring check script <v1.0>\n";
print "  Author: Noon Chen\n";
print "  A Professional Tool for Test.\n";
print "  ",scalar localtime;
print "\n*****************************************************************************\n";

use strict;
use warnings;
use List::Util 'uniq';

############################### process fixture.o ########################################

print  "\n  >>> processing fixture.o ... \n\n";
my $Nnum = 0;	#node numbers
my $Wnum = 0;   #Wire numbers
my @shorts = ();
my @Spins =();
my @pins =();
my $short_pair = '';
my $BRC = '';
my $BRCbuffer = '';
my @node = '';
my @nodes = '';
my $panel = "";

my $wirelist = "wirelist.o";

if(-e $wirelist){
	print "  project files found.\n\n";
	}
else{
	print "  fixture only project.\n\n";
# Generate the demo config file for full bank
	open (Config, ">config");
	print Config "!!!!    5    0    2 1493432712  Vc903                                         \n";
	print Config "target hp3073 standard\n";
	print Config "enable common delimiter\n";
	print Config "enable express fixturing\n";
	print Config "enable software revision b\n";

	print Config "module 0\n";
	print Config "cards 1 asru c revision\n";
	print Config "cards 2 to 5 hybrid standard double density\n";
	print Config "cards 6 control xt\n";
	print Config "cards 7 to 11 hybrid standard double density\n";
	print Config "end module\n";

	print Config "module 1\n";
	print Config "cards 1 asru c revision\n";
	print Config "cards 2 to 5 hybrid standard double density\n";
	print Config "cards 6 control xt\n";
	print Config "cards 7 to 11 hybrid standard double density\n";
	print Config "end module\n";

	print Config "module 2\n";
	print Config "cards 1 asru c revision\n";
	print Config "cards 2 to 5 hybrid standard double density\n";
	print Config "cards 6 control xt\n";
	print Config "cards 7 to 11 hybrid standard double density\n";
	print Config "end module\n";

	print Config "module 3\n";
	print Config "cards 1 asru c revision\n";
	print Config "cards 2 to 5 hybrid standard double density\n";
	print Config "cards 6 control xt\n";
	print Config "cards 7 to 11 hybrid standard double density\n";
	print Config "end module\n";

	close Config;
	#my $value = system ("comp 'config' -l > Null");
	
# Generate the demo board file
	open (Board, ">board");
	print Board "HEADING\n";
	close Board;
	#system ("check board 'board'");
	#$value = system ("bcomp 'board' -l > Null");
	
# Gerarate the demo board_xy file
	open (Boardxy, ">board_xy");
	print Boardxy "!!!!   15    1    1 1469081253   0000                                         \n";
	print Boardxy "	UNITS  MILS;\n";
	print Boardxy "	SCALE  0.1;\n";

	open (Fixture, "<fixture/fixture.o");
	while (my $array = <Fixture>)
	{
		$array =~ s/(^\s+|\s+$)//g;
		if($array =~ "PLACEMENT")
		{
			print Boardxy "	",$array,"\n";
			while($array = <Fixture>)
			{
				$array =~ s/(^\s+|\s+$)//g;
				last if ($array =~ "NODE|BOARD|KEEPOUT");
				print Boardxy "	",$array,"\n";
				}
			}
		}
	close Fixture;
	close Boardxy;
	#$value = system ("bcomp 'board_xy' -l > Null");

# Gerarate the demo wirelist file
	open (Wirelist, ">wirelist");
	print Wirelist "!!!!   10    0    1 1504779331   0000                                         \n";
#	print Wirelist "test shorts \"fix_pins\"","\n";
#	print Wirelist "end test\n";
#	print Wirelist "test shorts \"fix_shorts\"","\n";
#	print Wirelist "end test\n";
	close Wirelist;
	#$value = system ("wcomp 'wirelist' -l > Null");
	}


open (fix_pins, ">fix_pins");
open (fix_shorts, ">fix_shorts");
print fix_pins "!!!!   16    0    1 1460865776   0000                                         \n";
print fix_shorts "!!!!    9    0    1 1460733871   0000                                         \n";

open (Fixture, "< ./fixture/fixture.o");
open (Report, ">Details.txt");
	while(my $LIST = <Fixture>)
	{
		$LIST =~ s/(^\s+|\s+$)//g;		#clear all non-character symbol
		next if(!$LIST);				#goto next if it's empty
		my @nodes = split('\s+', $LIST);
		last if ($LIST eq "PROTECTED UNIT");
		if ($LIST =~ "END PANEL"){$panel = "True";}

		if($nodes[0] eq "NODE")
		{
			$LIST = <Fixture>;
			$LIST =~ s/(^\s+|\s+$)//g;
			next if(!$LIST);			#goto next if it's empty
			if($LIST ne "PROBES")
			{
				$Nnum++;
				if($nodes[1] =~ '\%'){$nodes[1] = substr($nodes[1], 3, -1)}
				if($nodes[1] =~ '\"'){$nodes[1] = substr($nodes[1], 1, -1)}
				#next if($nodes[1] =~ /(^NC_|_NC$|NONE)/);	#eliminate NC nets
				print "Probe\#:$Nnum	$nodes[1]\n";
				print Report "	#$Nnum\n";
				print Report "$nodes[1]\n";
				while($LIST = <Fixture>)
				{
					$LIST =~ s/(^\s+|\s+$)//g;
					last if(!$LIST);		#exit loop if it's none-character symbol				
					if($LIST eq "WIRES")
					{
						my @pair = ();
						#print @pair."\n";
						my $BRCnum = 0;	#BRC numbers
						while($LIST = <Fixture>)
						{
							$LIST =~ s/(^\s+|\s+$)//g;	   #clear all non-character symbol
							goto NEXT_NODE if(!$LIST);		#exit loop if it's none-character symbol
							@node = split('\s+', $LIST);
							if($node[0] !~ /(\D+)/) {($BRC) = $node[0] =~ /(\d+)/;
								next if(substr($BRC,-2) =~ /(19|20|39|40|59|60)/);	#eliminate fixed GROUND
								next if(substr($BRC,0,3) =~ /(201|213|111|123|106|118|206|218)/);	#eliminate ASRU/Control card				
								next if($BRCbuffer eq $BRC);
								$Wnum++;
								print "   Wire\#:$Wnum	",$BRC,"\n";
								print Report $BRC."\n";
								$BRCbuffer = $BRC;
								unshift(@pair, $BRC);
								if($BRCnum > 0)		#collect shorts data
								{
									#print $BRC,"\n";
									if($BRC < $pair[$BRCnum]){$short_pair = $BRC." to ".$pair[$BRCnum]."\n";}
									if($BRC > $pair[$BRCnum]){$short_pair = $pair[$BRCnum]." to ".$BRC."\n";}
									print Report " -- ".$short_pair;
									#push(@shorts, "short ".$short_pair);
									push(@shorts, 'failure '.'" >> Node: '.$nodes[1].'"'."\n"."  short ".$short_pair);
									push(@pins, "nodes  ".$BRC."  \!$nodes[1]\n");
									push(@Spins, 'failure '.'" >> Node: '.$nodes[1].'"'."\n"."  nodes  ".$BRC."\n");
									#print @shorts;
									}
								else		#collect pins data
								{
									push(@pins, "nodes  ".$BRC."  \!$nodes[1]\n");
									push(@Spins, 'failure '.'" >> Node: '.$nodes[1].'"'."\n"."  nodes  ".$BRC."\n");
									}
								$BRCnum++;
								}
							}
						}
					}
				}
			}
		NEXT_NODE:
		}
	my @unique_pins = uniq @pins;
	my @unique_Spins = uniq @Spins;
	my @unique_shorts = uniq @shorts;

	print "\n\tShorts Scale: ".scalar@unique_shorts."\n";
	print fix_shorts "! Shorts Scale: ".scalar@unique_shorts."\n";
	print "\tNodes Scale: ".scalar@unique_Spins;
	print fix_shorts "! Nodes Scale: ".scalar@unique_Spins."\n";
	print fix_pins "! Nodes Scale: ".scalar@unique_pins."\n";

	print fix_shorts "  threshold 12\n  settling delay 1m\n";
	print fix_shorts sort @unique_shorts;
	print fix_shorts 'failure ""'."\n";
	print fix_shorts '!#########################################################################################'."\n";

	print fix_shorts "  threshold 1000\n";
	print fix_shorts sort @unique_Spins;
	print fix_shorts 'failure ""'."\n";
	print fix_pins sort @unique_pins;

close Report;
close Fixture;
close fix_shorts;
close fix_pins;


	open (Wirelist, ">>wirelist");
	print Wirelist "\ntest shorts \"fix_pins\"","\n";
	print Wirelist "end test\n";
	print Wirelist "test shorts \"fix_shorts\"","\n";
	print Wirelist "end test\n";
	close Wirelist;

if ($panel eq "True"){
	rename "fix_pins", "1%fix_pins";
	rename "fix_shorts", "1%fix_shorts";
	print  "\n	>>> '1%fix_pins','1%fix_shorts' file generated ... \n";
	}
else{
	print  "\n	>>> 'fix_pins','fix_shorts' file generated ... \n";
	}

print "\n  >>> done ...\n\n";

# print "\n";
# system 'pause';
# exit;

##########################################################################################


