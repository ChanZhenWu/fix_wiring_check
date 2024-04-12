print "\n*****************************************************************************\n";
print "  3070 wiring check script <v0.2>\n";
print "  Author: Noon Chen\n";
print "  A Professional Tool for Test.\n";
print "  ",scalar localtime;
print "\n*****************************************************************************\n";

use strict;
use warnings;
use List::MoreUtils 'uniq';

############################### process fixture.o ########################################

print  "\n  >>> processing fixture.o ... \n\n";
my $Nnum = 0;	#node numbers
my $Wnum = 0;   #Wire numbers
my @shorts = ();
my @pins =();
my $short_pair = '';
my $BRC = '';
my @node = '';
my @nodes = '';

open (fix_pins, ">fix_pins");
open (fix_shorts, ">fix_shorts");

open (Fixture, "< ./fixture/fixture.o");
open (Report, ">Details.txt");
	while(my $LIST = <Fixture>)
		{
		$LIST =~ s/(^\s+|\s+$)//g;		#clear all non-character symbol
		next if(!$LIST);				#goto next if it's empty
		my @nodes = split('\s+', $LIST);
		if ($LIST eq "PROTECTED UNIT"){last;}

		if($nodes[0] eq "NODE")
			{
			$LIST = <Fixture>;
			$LIST =~ s/(^\s+|\s+$)//g;
			next if(!$LIST);			#goto next if it's empty
			if($LIST ne "PROBES")
				{
				$Nnum++;
				if($nodes[1] =~ '\%'){$nodes[1] = substr($nodes[1], 3, -1)}
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
								$Wnum++;
								print "   Wire\#:$Wnum	",$BRC,"\n";
								print Report $BRC."\n";
								unshift(@pair, $BRC);
								if($BRCnum > 0)		#collect shorts data
									{
									#print $BRC,"\n";
									if($BRC < $pair[$BRCnum]){$short_pair = $BRC." to ".$pair[$BRCnum]."	\!".$nodes[1]."\n";}
									if($BRC > $pair[$BRCnum]){$short_pair = $pair[$BRCnum]." to ".$BRC."	\!".$nodes[1]."\n";}
									print "	",$short_pair;
									push(@shorts, "short ".$short_pair);
									push(@pins, "nodes  ".$BRC."	\!$nodes[1]\n");
									#print @shorts;
								}
								else		#collect pins data
									{
									push(@pins, "nodes  ".$BRC."	\!$nodes[1]\n");
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
	my @unique_shorts = uniq @shorts;

	print fix_shorts "  threshold 12\n  settling delay 1m\n";
	print fix_shorts sort @unique_shorts;
	print fix_shorts "  threshold 1000\n";

	print fix_shorts sort @unique_pins;
	print fix_pins sort @unique_pins;

close Report;
close Fixture;
close fix_shorts;
close fix_pins;


print "\n  >>> done ...\n\n";


##########################################################################################


